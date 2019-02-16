#!/bin/bash
#******************************************#
#     File Name: KleineWelle/functions.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/24 10:50:00
#******************************************#

:

#--------------------------------------------------------#
# Usage: __get_periodic_gps_epoch  INTERVAL
#    Arguments:
#       INTERVAL: interval time in minute
#--------------------------------------------------------#
function __get_periodic_gps_epoch(){
    INTERVAL=${1}

    [ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime
    
    let mm="`date +"%M"`"/${INTERVAL}*${INTERVAL}
    jst_end="`date +"%Y-%m-%d %H:${mm}:00"`"
    ${cmd_gps} ${jst_end} | head -3 | tail -1 | awk '{printf("%d\n", $2)}'
}

