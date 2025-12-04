# Text Swordsman

## awk

### 基本语法

```bash
awk [POSIX or GNU style options] -f progfile [--] file
POSIX options:          GNU long options: (standard)
        -f progfile             --file=progfile
        -F fs                   --field-separator=fs
        -v var=val              --assign=var=val

-F fs          # fs指定输入分隔符，fs 可以是字符串或正则表达式，如-F:
-v var=val     # 赋值一个用户定义变量，将外部变量传递给awk
-f progfile    # 从脚本文件中读取awk命令


# example
awk -F':' '{print $1}' /etc/passwd
awk 'BEGIN { print "Don\47t Panic!" }'


# 运行 awk 程序，打印每行输入流的第一列
awk '{print $1}'


# awk 文件方式执行
cat > demo.awk << "EOF"
#! /bin/awk -f
BEGIN { print "Don't Panic!" }
EOF
# 运行
awk -f demo.awk top.txt
chmod +x demo.awk && ./demo.awk
```

### 变量

| 变量        | 说明                                       |     |
| ----------- | ------------------------------------------ | --- |
| ARGC        | 命令行参数数量                             |     |
| ARGIND      | 命令行中当前文件的位置（从0开始算）        |     |
| ARGV        | 包含命令行参数的数组                       |     |
| CONVFMT     | 数字转换格式（默认值为%.6g）               |     |
| ENVIRON     | 环境变量关联数组                           |     |
| ERRNO       | 最后一个系统错误的描述                     |     |
| FIELDWIDTHS | 字段宽度列表（用空格键分隔）               |     |
| FILENAME    | 当前输入文件的名称                         |     |
| FNR         | 同NR，但相对于当前文件                     |     |
| FS          | 字段分隔符（默认是任何空格）               |     |
| IGNORECASE  | 如果为真，则进行忽略大小写的匹配           |     |
| NF          | 表示字段数，在执行过程中对应于当前的字段数 |     |
| NR          | 表示记录数，在执行过程中对应于当前的行号   |     |
| FILENAME    | 当前输入文件的名                           |     |
| OFMT        | 数字的输出格式（默认值是%.6g）             |     |
| OFS         | 输出字段分隔符（默认值是一个空格）         |     |
| ORS         | 输出记录分隔符（默认值是一个换行符）       |     |
| RS          | 记录分隔符（默认是一个换行符）             |     |
| RSTART      | 由match函数所匹配的字符串的第一个位置      |     |
| RLENGTH     | 由match函数所匹配的字符串的长度            |     |
| SUBSEP      | 当前输入文件的名                           |     |
| FILENAME    | 数组下标分隔符（默认值是34）               |     |

### 函数 && 条件

```bash
# 常用函数
# tolower()：字符转为小写。
# length()：返回字符串长度。
# substr()：返回子字符串。
# sin()：正弦。
# cos()：余弦。
# sqrt()：平方根。
# rand()：随机数。

# 转换大写示例
awk -F ':' '{ print toupper($1) }' /etc/passwd


# if 条件语句
awk -F ':' '{if ($1 > "m") print $1; else print "---"}' /etc/passwd

```

### 常用用法

```bash
awk 'BEGIN{ commands } pattern{ commands } END{ commands }'
首先执行 BEGIN 语句块，只会执行一次。通常用于变量初始化，头行打印一些表头信息，在通过stdin读入数据前就被执行。
每读取一行数据使用 pattern{ commands }循环处理数据。
最后执行 END 语句块，只会执行一次，通常用于统计结果。

# example
cat /etc/passwd |awk  -F ':'  'BEGIN {print "name,shell"}  {print $1","$7} END {print "blue,/bin/nosh"}'


# file
tee top.txt << "EOF"
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 213123 root      20   0    9584   4060   3344 R   6.2   0.1   0:00.01  top
1275702 tomcat    20   0    999    30596  13976 S  6.2   0.4 741:21.61  metrics
1612431 systemd   20   0    888    7708 103788 S   6.2   9.6   2519:09  k3s
      1 systemd   20   0    777    1884   6596 S   0.0   0.1  43:55.21  systemd
EOF

# 格式化输出
# - 左对齐
# %s 字符串
# %d 十进制有符号整数
# %u 十进制无符号整数
awk '{printf "%-8s %-8s %-8s %-18s\n",NR, $1,$2,$12}' top.txt

# 计算结果
awk 'BEGIN {sum=0} {printf "%-8s %-8s %-18s\n", $1, $9, $11; sum+=$9} END {print "cpu sum:"sum}' top.txt

# 外部引用变量
awk -v sum=0 '{printf "%-8s %-8s %-18s\n", $1, $9, $11; sum+=$9} END {print "cpu sum:"sum}' top.txt

# 筛选
awk 'NR>1 && $9>0 {printf "%-8s %-8s %-18s\n",$1,$9,$12}' top.txt
awk 'NR==1 || $2~/tomcat/ {printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12}' top.txt

# action 块筛选
awk '{if($9>0){printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12}}' top.txt

# 数组计算第二列的用户进程数量
awk 'NR!=1{a[$2]++;} END {for (i in a) print i ", " a[i];}' top.txt


# 数组操作
# 获取长度
awk 'BEGIN{info="it is a test";lens=split(info,tA," ");print length(tA),lens;}'
# 循环输出，下标从1开始
awk 'BEGIN{info="it is a test";split(info,tA," ");for(k in tA){print k,tA[k];}}'
awk 'BEGIN{info="it is a test";tlen=split(info,tA," ");for(k=1;k<=tlen;k++){print k,tA[k];tlen;}}'
# 判断 key in array（判断语法为 key in array）
awk 'BEGIN{tB["a"]="a1";tB["b"]="b1";if("c" in tB){print "ok";};for(k in tB){print k,tB[k];}}'
# 删除 key
awk 'BEGIN{tB["a"]="a1";tB["b"]="b1";delete tB["a"];for(k in tB){print k,tB[k];}}'


# 判断字符拆分输出文件
awk 'NR>1 {if($0~/tomcat/){printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12 > "1.txt"}else if($0~/root/){printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12 > "2.txt"}else{printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12 > "3.txt"}}' top.txt


# 删除关键字 memory 的重复行
awk '!seen[$0]++ || !/memory/' values.yaml
# 删除并修改原文件
awk '!seen[$0]++ || !/memory/' values.yaml > tmp && mv -v tmp values.yaml


# 替换 ORS, 去除换行符
awk 'BEGIN{ORS=""};{print $0}' x.txt

```

## grep

### 基本语法

```bash

```

### 常用用法

```bash

```

## sed

### 基本语法

```bash
sed [OPTION]... {script-only-if-no-other-script} [input-file]...

# options
  -n, --quiet, --silent
  -e script, --expression=script
  -f script-file, --file=script-file
  -E, -r, --regexp-extended
  -i[SUFFIX] edit files in place (makes backup if SUFFIX supplied)

# action
a\：追加行，a\的后面跟上字符串s(多行字符串可以用\n分隔)，则会在当前选择的行的后面都加上字符串s
c\：替换行，c\后面跟上字符串s(多行字符串可以用\n分隔)，则会将当前选中的行替换成字符串s
i\：插入行，i\后面跟上字符串s(多行字符串可以用\n分隔)，则会在当前选中的行的前面都插入字符串s
d：删除行，该命令会将当前选中的行删除
p：打印，该命令会打印当前选择的行到屏幕上
y：替换字符，用法：y/Source-chars/Dest-chars/，分割字符/可以用任意单字符代替，用Dest-chars中对应位置的字符替换掉Soutce-chars中对应位置的字符
s：替换字符串，用法：s/Regexp/Replacement/Flags，分隔字符/可以用其他任意单字符代替，用Replacement替换掉匹配字符串

# flags
g：将用Replacement替换模版空间中所有匹配Regexp的部分，则不仅仅是第一个匹配部分
digit：只用Replacement替换模版空间中第digit(digit是1至9)个匹配Regexp的部分
p：若发生了替换操作，指示显示模版空间中新的数据
w file-name：若发生了替换操作，指示将模版空间中新的数据写入指定的文件file-name中
i：表示进行Regexp匹配时，是不区分大小写字母的


# example
sed -e 's/tomcat/fff/' -e 's/root/xxx/' top.txt

# insert or append new line
nl top.txt | sed '2i newline'
nl top.txt | sed '2a newline'
# delete line
nl top.txt | sed '2,3d'
nl top.txt | sed '3,$d'
# change and print
nl top.txt | sed '2c new content'
nl top.txt | sed -n '2,3p'

# search and delete
nl top.txt | sed '/tomcat/d' top.txt
# search and execute
nl top.txt | sed -n '/tomcat/{s/tomcat/xxx/;p}'

# replace and print
sed -p 's/tomcat/fff/p' top.txt
# regex replace
sed -r 's/xxx[[::space::]]/root/' top.txt


# replace files and backup to top.txt_bk_xxx
sed -i_bk_xx 's/tomcat/fff/p' top.txt
```

### 常用用法

```bash
# file
tee top.txt << "EOF"
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 213123 root      20   0    9584   4060   3344 R   6.2   0.1   0:00.01  top
1275702 tomcat    20   0    999    30596  13976 S  6.2   0.4 741:21.61  metrics
1612431 systemd   20   0    888    7708 103788 S   6.2   9.6   2519:09  k3s
      1 systemd   20   0    777    1884   6596 S   0.0   0.1  43:55.21  systemd
EOF

# search and append new line
sed -n '/requests/a\  cpu: 1000m\n  memory: 1Gi' values.yaml

# search and replace next line
sed -i '/autoscaling:/{n;s/enabled: true/enabled: false/}' values.yaml
```

> 1. [gawk official](https://www.gnu.org/software/gawk/manual/gawk.html)
> 2. [sed official](https://www.gnu.org/software/sed/manual/sed.html)
