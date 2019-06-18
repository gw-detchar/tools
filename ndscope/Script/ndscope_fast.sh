#!/bin/bash
#******************************************#
#     File Name: ndscope/ndscope_fast.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/05/28 23:04:10
#******************************************#

BIN=/usr/bin/ndscope
CHANS=/opt/rtcds/kamioka/k1/chans/daq/

[ "$1" = "" ] && echo "Usage: $0 channel" && exit 1
INCH=$1

OUTCH=`printf ${INCH} | sed -e 's/OUT16/OUT/g' -e 's/OUTMON/OUT/g' -e 's/OUTPUT/OUT/g' -e 's/INMON/IN1/g'`

if test "`grep -h ${OUTCH}_DQ ${CHANS}*.ini | grep -v '^#'`" = ""
then
    :
else
    OUTCH=${OUTCH}_DQ
fi

${BIN} ${OUTCH}
