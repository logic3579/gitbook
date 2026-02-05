# iptables

## Introduction

### Description

```markdown
# install

apt install iptables

# iptables

Kernel module ip_tables, view kernel info with modinfo ip_tables
User space tool that calls netfilter

# netfilter

Webhook points in kernel space
```

### iptables tables

- tables property

```markdown
# raw

Kernel module iptable_raw
Determines packet state tracking mechanism handling

# mangle

Kernel module iptable_mangle
Modifies packet TOS, TTL, MARK tags to enable QOS adjustments and policy routing. Requires router device support

# nat

Kernel module iptable_nat
Modifies packet IP address, port, and other information. Packets belonging to the same flow are processed only once

# filter

Kernel module iptable_filter
Filters packets, decides whether to allow or block based on rules
```

- Data packet connection state

```markdown
NEW: Packet initiating a new connection
ESTABLISHED: After sending and receiving a reply, the connection is established and enters the ESTABLISHED state, matching all subsequent packets of this connection
RELATED: Packets related to an established connection. e.g. FTP data transfer connections, --icmp-type 0 reply packets
INVALID: Packets that cannot be connected or have no state, such as unknown ICMP error messages
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

1. Inbound packet flow
   Processed by the PREROUTING chain (whether to modify packet addresses, etc.). If the routing decision determines the destination is local, the kernel passes it to the INPUT chain for processing. If it passes, it is delivered to the upper-layer application.
2. Forwarded packet flow
   Processed by the PREROUTING chain. If the routing decision determines the destination is another external address, the kernel passes it to the FORWARD chain (whether to forward or block), then to the POSTROUTING chain (whether to modify packet addresses, etc.) for processing.
3. Outbound packet flow
   Packets sent from the local machine to external addresses are first processed by the OUTPUT chain. After the routing decision, they are passed to the POSTROUTING chain (whether to modify packet addresses, etc.) for processing.
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
# After matching a rule, continue matching the next rule in the current chain

LOG: Log packet information, depends on rsyslog
MARK: Mark the packet, providing conditions for subsequent filtering
REDIRECT: Redirect the packet to another port

# After matching a rule, terminate current chain rules and move to the next rule chain (nat -> filter)

ACCEPT: Allow the packet through
SNAT: Source address translation
MASQUERADE: A special form of SNAT, masquerades as the automatically obtained IP of the network interface
DNAT: Destination address translation
RETURN: End the filter processing of the rule chain and return to the main rule chain (used in user-defined chains)

# Terminate matching and exit the filter processing

DROP: Drop the packet
REJECT: Reject the packet and send a rejection response
MIRROR: Mirror the packet, swap source IP and destination IP
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
