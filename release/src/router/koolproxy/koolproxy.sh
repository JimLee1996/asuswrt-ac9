# Koolproxy Script
# by JimLee1996

koolproxy_enable=$(nvram get koolproxy_enable)
koolproxy_video_only=$(nvram get koolproxy_video_only)
kpbin_url="http://koolproxy-bin.b0.upaiyun.com"
kprule_url="http://kprules.b0.upaiyun.com"

stop_kp() {
    # purge iptable rules
    iptables -t nat -D PREROUTING -p tcp -j KOOLPROXY 2>/dev/null
    iptables -t nat -F KOOLPROXY 2>/dev/null
    iptables -t nat -X KOOLPROXY 2>/dev/null

    # kill process
    killall -9 koolproxy 2>/dev/null

    logger -t [koolproxy] "stopped"
}

start_kp() {
    # start process
    /tmp/koolproxy/koolproxy -d

    # generate proxy rules
    iptables -t nat -N KOOLPROXY 2>/dev/null
    iptables -t nat -F KOOLPROXY 2>/dev/null

    # ignore specific ip range
    iptables -t nat -A KOOLPROXY -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A KOOLPROXY -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A KOOLPROXY -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A KOOLPROXY -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A KOOLPROXY -d 224.0.0.0/4 -j RETURN

    # port forward
    iptables -t nat -A KOOLPROXY -p tcp --dport 80 -j REDIRECT --to-ports 3000 2>/dev/null

    # enable
    iptables -t nat -A PREROUTING -p tcp -j KOOLPROXY 2>/dev/null
}

restart_kp() {
    stop_kp
    sleep 2
    start_kp
}

prepare() {
    mkdir /tmp/koolproxy
    mkdir /tmp/koolproxy/data
    mkdir /tmp/koolproxy/data/rules

    wget -O /tmp/koolproxy/koolproxy $kpbin_url/arm
    chmod +x /tmp/koolproxy/koolproxy

    cat>/tmp/koolproxy/data/source.list<<EOF
0|koolproxy.txt|https://kprule.com/koolproxy.txt|静态规则
0|daily.txt|https://kprule.com/daily.txt|每日规则
1|kp.dat|https://kprule.com/kp.dat|视频规则
EOF

    wget -O /tmp/koolproxy/data/rules/kp.dat $kprule_url/kp.dat
    if [ "$koolproxy_video_only" != "1" ];then
        sed -i '1s/0/1/g;2s/0/1/g' /tmp/koolproxy/data/source.list
        wget -O /tmp/koolproxy/data/rules/koolproxy.txt $kprule_url/koolproxy.txt
        wget -O /tmp/koolproxy/data/rules/daily.txt $kprule_url/daily.txt
    fi
    logger -t [koolproxy] "download finished"
}

case "$1" in
    "start")
        if [ "$koolproxy_enable" != "1" ];then
            logger -t [koolproxy] "disabled"
            exit 0
        fi
        if [ ! -d "/tmp/koolproxy" ];then
            logger -t [koolproxy] "files not found, start download..."
            prepare
        fi
        restart_kp
    ;;
    "stop")
        stop_kp
    ;;
    "restart")
        restart_kp
    ;;
    *)
        echo "Koolproxy Script by JimLee1996."
    ;;
esac
