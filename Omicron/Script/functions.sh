#!/bin/bash
#******************************************#
#     File Name: Omicron/functions.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/23 18:49:33
#******************************************#

:

#--------------------------------------------------------#
# Usage: __mv_etg_ligo_convention  IFO  SRC_DIR  DST_DIR
#    Arguments:
#       IFO    : L1, H1, V1, K1
#
#       SRC_DIR: Output directory of Omicron
#                It should be same as "OUTPUT DIRECTORY"
#                  in the parameter file for Omicron.
#
#       DST_DIR: Root directory for storing ETG files
#                  in order to read from SummaryPage.
#--------------------------------------------------------#
# Omicron output:
#   "OUTPUT DIRECOTRY"/K1:FOO-BAR_BAZ/K1-FOO_BAR_BAZ_OMICRON-1234567890-60.xml
# gwtrigfind input:
#   /home/controls/triggers/K1/FOO_BAR_BAZ_OMICRON/12345/K1-FOO_BAR_BAZ_OMICRON-1234567890-60.xml.gz
#--------------------------------------------------------#
function __mv_etg_ligo_convention(){
    IFO=${1}
    SRC_DIR=${2}
    DST_DIR=${3}
    ETG=OMICRON

    #gzip -f ${SRC_DIR}/*/*.xml
    # If error of "argument list too long" happened                             
    gzip -r ${SRC_DIR}/*
    for dir_channel_old in ${SRC_DIR}/${IFO}*
    do
	dir_channel_new=`basename ${dir_channel_old} | sed -e "s/${IFO}://g" -e 's/-/_/g'`_${ETG}
	for xml_old in ${dir_channel_old}/*.xml.gz
	do
	    [ "`printf "${xml_old}\n" | grep '\*'`" != "" ] && continue
	    let gps5=`basename ${xml_old} | awk -F'-' '{print $3}'`/100000
	    mkdir -p ${DST_DIR}/${IFO}/${dir_channel_new}/${gps5}
	    xml_new=${DST_DIR}/${IFO}/${dir_channel_new}/${gps5}/`basename ${xml_old}`
	    mv ${xml_old} ${xml_new}
	done
    done
}

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
