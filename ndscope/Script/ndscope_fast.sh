#!/bin/bash
#******************************************#
#     File Name: ndscope/ndscope_fast.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/08/11 18:19:38
#******************************************#

BIN=/usr/bin/ndscope
CHANS=/opt/rtcds/kamioka/k1/chans/daq/

[ "$1" = "" ] && echo "Usage: $0 channel" && exit 1

INCHS=`echo "$@" | tr ' ' '\n' | sort | uniq | tr '\n' ' '`
for x in ${INCHS}
do
    INCH=$x

    if test "`grep -h ${INCH%*_MON}_DQ ${CHANS}*.ini`"
    then
	INCH=${INCH%*_MON}
    fi
    

    OUTCH=`printf ${INCH} | sed -e 's/OUT16/OUT/g' -e 's/OUTMON/OUT/g' -e 's/OUTPUT/OUT/g' -e 's/INMON/IN1/g'`

    if test "`grep -h ${OUTCH}_DQ ${CHANS}*.ini | grep -v '^#'`" = ""
    then
	:
    else
	OUTCH=${OUTCH}_DQ
    fi
    
    OUTCHS="${OUTCHS} ${OUTCH}"
done
${BIN} ${OUTCHS}
