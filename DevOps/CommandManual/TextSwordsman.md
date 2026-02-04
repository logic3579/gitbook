# Text Swordsman

## awk

### Basic Syntax

```bash
awk [POSIX or GNU style options] -f progfile [--] file
POSIX options:          GNU long options: (standard)
        -f progfile             --file=progfile
        -F fs                   --field-separator=fs
        -v var=val              --assign=var=val

-F fs          # fs specifies the input field separator, can be a string or regex, e.g. -F:
-v var=val     # assign a user-defined variable, pass external variables to awk
-f progfile    # read awk commands from a script file


# example
awk -F':' '{print $1}' /etc/passwd
awk 'BEGIN { print "Don\47t Panic!" }'


# run awk program, print the first column of each input line
awk '{print $1}'


# execute awk from file
cat > demo.awk << "EOF"
#! /bin/awk -f
BEGIN { print "Don't Panic!" }
EOF
# run
awk -f demo.awk top.txt
chmod +x demo.awk && ./demo.awk
```

### Variables

| Variable    | Description                                                    |
| ----------- | -------------------------------------------------------------- |
| ARGC        | Number of command-line arguments                               |
| ARGIND      | Index of the current file in the command line (starts from 0)  |
| ARGV        | Array containing command-line arguments                        |
| CONVFMT     | Number conversion format (default: %.6g)                       |
| ENVIRON     | Associative array of environment variables                     |
| ERRNO       | Description of the last system error                           |
| FIELDWIDTHS | Field width list (space-separated)                             |
| FILENAME    | Name of the current input file                                 |
| FNR         | Same as NR, but relative to the current file                   |
| FS          | Field separator (default: any whitespace)                      |
| IGNORECASE  | If true, perform case-insensitive matching                     |
| NF          | Number of fields in the current record                         |
| NR          | Number of records processed (current line number)              |
| OFMT        | Output format for numbers (default: %.6g)                      |
| OFS         | Output field separator (default: a space)                      |
| ORS         | Output record separator (default: a newline)                   |
| RS          | Record separator (default: a newline)                          |
| RSTART      | Start position of the string matched by match()                |
| RLENGTH     | Length of the string matched by match()                        |
| SUBSEP      | Array subscript separator (default: \034)                      |

### Functions & Conditions

```bash
# common functions
# tolower(): convert string to lowercase
# length(): return string length
# substr(): return substring
# sin(): sine
# cos(): cosine
# sqrt(): square root
# rand(): random number

# convert to uppercase example
awk -F ':' '{ print toupper($1) }' /etc/passwd


# if conditional statement
awk -F ':' '{if ($1 > "m") print $1; else print "---"}' /etc/passwd

```

### Common Usage

```bash
awk 'BEGIN{ commands } pattern{ commands } END{ commands }'
# BEGIN block executes once before reading input, typically used for variable initialization and printing headers.
# pattern{ commands } block executes for each input line.
# END block executes once after all input is processed, typically used for summary statistics.

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

# formatted output
# - left-align
# %s string
# %d signed decimal integer
# %u unsigned decimal integer
awk '{printf "%-8s %-8s %-8s %-18s\n",NR, $1,$2,$12}' top.txt

# calculate result
awk 'BEGIN {sum=0} {printf "%-8s %-8s %-18s\n", $1, $9, $11; sum+=$9} END {print "cpu sum:"sum}' top.txt

# reference external variable
awk -v sum=0 '{printf "%-8s %-8s %-18s\n", $1, $9, $11; sum+=$9} END {print "cpu sum:"sum}' top.txt

# filtering
awk 'NR>1 && $9>0 {printf "%-8s %-8s %-18s\n",$1,$9,$12}' top.txt
awk 'NR==1 || $2~/tomcat/ {printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12}' top.txt

# action block filtering
awk '{if($9>0){printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12}}' top.txt

# array: count process number per user in column 2
awk 'NR!=1{a[$2]++;} END {for (i in a) print i ", " a[i];}' top.txt


# array operations
# get length
awk 'BEGIN{info="it is a test";lens=split(info,tA," ");print length(tA),lens;}'
# loop output, index starts from 1
awk 'BEGIN{info="it is a test";split(info,tA," ");for(k in tA){print k,tA[k];}}'
awk 'BEGIN{info="it is a test";tlen=split(info,tA," ");for(k=1;k<=tlen;k++){print k,tA[k];tlen;}}'
# check key in array (syntax: key in array)
awk 'BEGIN{tB["a"]="a1";tB["b"]="b1";if("c" in tB){print "ok";};for(k in tB){print k,tB[k];}}'
# delete key
awk 'BEGIN{tB["a"]="a1";tB["b"]="b1";delete tB["a"];for(k in tB){print k,tB[k];}}'


# split output to different files based on pattern matching
awk 'NR>1 {if($0~/tomcat/){printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12 > "1.txt"}else if($0~/root/){printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12 > "2.txt"}else{printf "%-8s %-8s %-8s %-18s\n",$1,$2,$9,$12 > "3.txt"}}' top.txt


# remove duplicate lines containing keyword "memory"
awk '!seen[$0]++ || !/memory/' values.yaml
# remove duplicates and modify original file
awk '!seen[$0]++ || !/memory/' values.yaml > tmp && mv -v tmp values.yaml


# replace ORS, remove newlines
awk 'BEGIN{ORS=""};{print $0}' x.txt

```

## grep

### Basic Syntax

```bash

```

### Common Usage

```bash

```

## sed

### Basic Syntax

```bash
sed [OPTION]... {script-only-if-no-other-script} [input-file]...

# options
  -n, --quiet, --silent
  -e script, --expression=script
  -f script-file, --file=script-file
  -E, -r, --regexp-extended
  -i[SUFFIX] edit files in place (makes backup if SUFFIX supplied)

# action
a\: append line after the current selected line
c\: replace the current selected line with the given string
i\: insert line before the current selected line
d: delete the current selected line
p: print the current selected line to stdout
y: transliterate characters, usage: y/Source-chars/Dest-chars/, replace each character in Source-chars with the corresponding character in Dest-chars
s: substitute string, usage: s/Regexp/Replacement/Flags, the delimiter / can be replaced with any single character

# flags
g: replace all matches in the pattern space, not just the first
digit: replace only the Nth match (digit is 1-9)
p: if a substitution was made, print the pattern space
w file-name: if a substitution was made, write the result to the specified file
i: perform case-insensitive matching


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

### Common Usage

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
