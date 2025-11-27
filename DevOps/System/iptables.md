# iptables

## Introduction

### Description

```markdown
# install

apt install iptables

# iptables

内核模块 ip_tables，查看内核信息 modinfo ip_tables
user space 下的工具，调用 netfilter

# netfilter

kernel space 下的 webhook 点
```

### iptables tables

- tables property

```markdown
# raw

内核模块 iptable_raw
决定数据包状态跟踪机制处理

# mangle

内核模块 iptable_mangle
修改数据包 TOS、TTL、MARK 标记，实现 QOS 调整与策略路由。需要路由设备支持

# nat

内核模块 iptable_nat
修改数据包 IP 地址、端口等信息。属于一个流的包只会经过一次

# filter

内核模块 iptable_filter
过滤数据包，根据规则是否放行等
```

- Data packet connection state

```markdown
NEW：发起新连接的包
ESTABLISHED：发送并接到应答后，连接建立成为 EATAB 状态，匹配该连接后续所有数据包
RELATED：已建立连接相关的包。如 FTP 数据传输连接，--icmp-type 0 应答包
INVALID：无法连接或没有状态的包，如未知的 ICMP 错误信息包
```

- tables chain

```markdown
raw: PREROUTING, OUTPUT
mangle: PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING
nat: PREROUTING, OUTPUT, POSTROUTING
filter: INPUT, FORWARD, OUTPUT
```

- tables priority

```markdown
raw -> mangle -> nat -> filter(default)
```

### iptables chains

- chains property

```markdown
PREROUTING
INPUT
FORWARD
OUTPUT
POSTROUTING
```

- chains priority

```markdown
# To Localhost

PREROUTING -> INPUT -> OUTPUT -> POSTROUTING

# Forward

PREROUTING -> FORWARD -> POSTROUTING

# To External

OUTPUT -> POSTROUTING

# Packet flow direction

1. 入站数据包走向
   PREROUTING 链处理（是否修改数据包地址等），路由选择 routing decision 为本地，则内核将其传给 INPUT 链处理，如果通过则交给系统上层的应用程序。
2. 转发数据包走向
   PREROUTING 链处理，路由选择 routing decision 是其它外部地址，则内核将其传递给 FORWARD 链处理（是否转发或拦截），然后再交给 POSTROUTING 链（是否修改数据包的地址等）处理。
3. 出站数据包走向
   本机向外部地址发送的数据包，首先被 OUTPUT 链处理，路由选择 routing decision 后传递给 POSTROUTING 链（是否修改数据包的地址等）进行处理。
```

### iptables rules

- rules property

```markdown
# Parameter

--append -A chain Append to chain
--delete -D chain Delete matching rule from chain
--insert -I chain [rulenum] Insert in chain as rulenum (default 1=first)
--replace -R chain rulenum Replace rule rulenum (1 = first) in chain
--list -L [chain [rulenum]] List the rules in a chain or all chains
--list-rules -S [chain [rulenum]] Print the rules in a chain or all chains
--flush -F [chain] Delete all rules in chain or all chains
--zero -Z [chain [rulenum]] Zero counters in chain or all chains
--new -N chain Create a new user-defined chain
--delete-chanin -X [chain] Delete a user-defined chain
--policy -P chain target Change policy on chain to target

# Options

--protocol -p proto protocol: by number or name, eg. `tcp'
--source      -s address[/mask][...]  source specification
--destination -d address[/mask][...]  destination specification
--in-interface -i input name[+]       network interface name ([+] for wildcard)
--jump        -j target       target for rule (may load target extension)
--match       -m match        extended match (may load extension)
(eg: 
-m state --state ESTABLISHED,RELATED
-m tcp --sport 9999, -m multiport --dports 80,8080
-m icmp --icmp-type 8
)
--numeric     -n              numeric output of addresses and ports
--out-interface -o output name[+]     network interface name ([+] for wildcard)
--table       -t table        table to manipulate (default: `filter')
--verbose -v verbose mode
--line-numbers print line numbers when listing
```

- target and rule

```markdown
# 匹配到规则后，继续匹配当前链下一条规则

LOG：记录数据包日志，取决于 rsyslog
MARK：标记数据包，为后续的过滤提供条件
REDIRECT：重定向数据包到另一个端口

# 匹配到规则后，终止当前队列规则，转到下一规则链（nat -> filter）

ACCEPT: 放行数据包
SNAT：源地址转换
MASQUERADE：SNAT 的特殊方式，伪装为自动获取网卡的 IP
DNAT：目的地址转换
RETURN：结束规则链的过滤程序，返回主规则链（自定义链中使用）

# 终止匹配，退出过滤程序

DROP：丢弃数据包
REJECT：拒绝数据包，响应拒绝信息
MIRROR：镜像数据包，调换源 IP 与目的 IP
```

## Command

### Common

```bash
# config file
/etc/sysconfig/iptables
# save to config file
iptables-save > /tmp/iptables
# restore from config file
iptables-restore < /etc/sysconfig/iptables
# service control
/etc/init.d/iptables {start|stop|save|restart|force-reload}


# view all rules(default filter chain)
iptables -S
iptables -nL
# view specified rules
iptables -nL INPUT
iptables -nL -t nat FORWARD
# view all rules with line numbers
iptables -nL -t filter --line-numbers
# insert and append rule
iptables -I INPUT -s 1.1.1.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# replace and delete rule
iptables -R INPUT 1 -s 1.1.1.1 -j DROP
iptables -D 2
iptables -D INPUT -p tcp --dport 80 -j ACCEPT
# change default policy
iptables -P INPUT DROP
# flush chain rules and delete user-defined chain
iptables -F
iptables -X
# invert !
iptables -A FORWARD -i docker0 ! -o docker0 -j ACCEPT

```

### Example

```bash
# init
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -m state --state INVALID,NEW -j DROP

# log
iptables -t filter -I INPUT -j LOG --log-prefix "*** INPUT ***" --log-level debug
# redirect
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080
# reject
iptables -t filter -A FORWARD -p TCP --dport 22 -j REJECT --reject-with tcp-reset
# mark
iptables -t nat -A PREROUTING -p tcp --dport 22 -j MARK --set-mark 2

# nat
iptables -t nat -A PREROUTING -p tcp -d 8.8.8.8 --dport 80 -j DNAT --to-destination 192.168.1.1-192.168.1.10:80-100
iptables -t nat -A POSTROUTING -s 10.10.1.0/24 -j SNAT --to-source 8.8.8.8
iptables -t nat -A POSTROUTING -s 10.10.2.0/24 -o eth0 -j MASQUERADE
```

> Reference:
>
> 1. [iptables wiki](https://en.wikipedia.org/wiki/Iptables)
