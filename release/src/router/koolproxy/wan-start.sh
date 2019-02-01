#!/bin/sh

logger -t [wan-start.sh] "run myscript_wan_start in nvram"
myscript_wan_start=$(nvram get myscript_wan_start)
($myscript_wan_start)
logger -t [wan-start.sh] "myscript_wan_start finished"

sleep 5

logger -t [wan-start.sh] "run koolproxy script"
/usr/bin/kp_start

logger -t [wan-start.sh] "exit"
exit 0
