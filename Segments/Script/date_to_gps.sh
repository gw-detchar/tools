#!/bin/bash

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime
jst_end="$1 9:00:00"
GPS_END=`${cmd_gps} ${jst_end} | head -3 | tail -1 | awk '{printf("%d\n", $2)}'`

echo $GPS_END
