#!/bin/bash

# 设置默认间隔时间（秒）
INTERVAL=${1:-3}

# 检测操作系统类型
OS="$(uname -s)"

# 获取默认网络接口
get_interface() {
    case $OS in
        "Darwin") # macOS
            INTERFACE=$(netstat -rn | grep default | head -n1 | awk '{print $NF}')
            # 如果没找到，使用 en0
            if [ -z "$INTERFACE" ]; then
                INTERFACE="en0"
            fi
            ;;
        "Linux")
            # 尝试使用 ip 命令
            if command -v ip >/dev/null 2>&1; then
                INTERFACE=$(ip route | grep default | cut -d' ' -f5)
            else
                # 回退到检查常用接口
                for iface in eth0 wlan0 ens33 enp0s3; do
                    if [ -e "/sys/class/net/$iface" ]; then
                        INTERFACE=$iface
                        break
                    fi
                done
            fi
            ;;
    esac

    if [ -z "$INTERFACE" ]; then
        echo "No interface"
        exit 1
    fi

    echo $INTERFACE
}

# 获取接口流量数据
get_bytes() {
    INTERFACE=$1
    case $OS in
        "Darwin")
            netstat -I $INTERFACE -b | tail -n1 | awk '{print $7" "$10}'
            ;;
        "Linux")
            rx=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
            tx=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
            echo "$rx $tx"
            ;;
    esac
}

# 格式化速率显示
format_speed() {
    local bytes=$1
    if [ $bytes -gt 1048576 ]; then
        echo "$(echo "scale=1; $bytes/1048576" | bc)MB/s"
    elif [ $bytes -gt 1024 ]; then
        echo "$(echo "scale=1; $bytes/1024" | bc)KB/s"
    else
        echo "${bytes}B/s"
    fi
}

# 主逻辑
main() {
    INTERFACE=$(get_interface)
    
    # 第一次读取
    read R1 T1 <<< $(get_bytes $INTERFACE)
    sleep $INTERVAL
    # 第二次读取
    read R2 T2 <<< $(get_bytes $INTERFACE)

    # 计算速率
    RBPS=$(( $R2 - $R1 ))
    TBPS=$(( $T2 - $T1 ))

    # 确保值非负
    [ $RBPS -lt 0 ] && RBPS=0
    [ $TBPS -lt 0 ] && TBPS=0

    # 格式化显示
    RX=$(format_speed $RBPS)
    TX=$(format_speed $TBPS)

    echo "↓$RX ↑$TX"
}

main
