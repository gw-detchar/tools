#!/bin/bash

# Copied from /home/detchar/git/kagra-detchar/tools/Omicron/Script/functions.sh 
function __get_periodic_gps_epoch(){
    INTERVAL=${1}

    [ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

    let mm="`date +"%M"`"/${INTERVAL}*${INTERVAL}
    
    echo mm
    echo $mm
    jst_end="`date +"%Y-%m-%d %H:${mm}:00"`"
    ${cmd_gps} ${jst_end} | head -3 | tail -1 | awk '{printf("%d\n", $2)}'
}

CRON_INTERVAL=15

#let GPS_END=`__get_periodic_gps_epoch ${CRON_INTERVAL}`-${OVERLAP}/2
#let GPS_END=`__get_periodic_gps_epoch ${CRON_INTERVAL}`

INTERVAL=15

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

let mm="`date +"%M"`"/${INTERVAL}*${INTERVAL}

jst_end="`date +"%Y-%m-%d %H:${mm}:00"`"

GPS_END=`${cmd_gps} ${jst_end} | head -3 | tail -1 | awk '{printf("%d\n", $2)}'`

echo $GPS_END
