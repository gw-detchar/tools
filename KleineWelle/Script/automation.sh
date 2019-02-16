#!/bin/bash
#******************************************#
#     File Name: KleineWelle/automation.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/31 16:23:40
#******************************************#

################################
### Set variable
################################
DET_ROOT=/users/DET
DET_KW=${DET_ROOT}/tools/KleineWelle
FILE_PARAM=${DET_KW}/Parameter/test.txt
FILE_FFL=/users/DET/Cache/latest.ffl
CMD_KW=/usr/bin/kleineWelleM
CRON_INTERVAL=15 # Need to match the interval of omicron on the cron job. [min.]
# ETG_DIR=/home/controls/triggers
ETG_DIR=/home/controls/triggers/K-KW_TRIGGERS
IFO=K1

################################
### KleineWelle parameter
################################
if test -e "${1}"
then
    FILE_PARAM=${1}
    STR_PARAM=`cat ${1}`
    printf ""
else
    STR_PARAM=`cat <<EOF | tee ${FILE_PARAM}
stride 16
basename K-KW_TRIGGERS
transientDuration 4.0
significance 2.0
threshold 3.0
decimateFactor -1
channel K1:IMC-MCL_SERVO_OUT_DQ 16 1024 2
EOF`
fi

###################################################################################################
###################################################################################################
###   Don't touch below
###################################################################################################
###################################################################################################
source ${DET_KW}/Script/functions.sh
BASE=`grep basename ${FILE_PARAM} | awk '{print $2}'`


################################
### Time epoch
################################
let GPS_END=`__get_periodic_gps_epoch ${CRON_INTERVAL}`
let GPS_START=${GPS_END}-${CRON_INTERVAL}*60


################################
### Execute
################################
awk -v "a=${GPS_START}" -v "b=${GPS_END}" '{if($2>=a-31 && $2<b) print $1}' ${FILE_FFL} > /tmp/kw-${GPS_START}-auto_filelist.txt
echo ""
if test "${BASE}" = ""
then
     echo "basename K-KW_TRIGGERS" >> ${FILE_PARAM}
elif test "${BASE}" != "K-KW_TRIGGERS"
then
    sed -i -e "s/basename ${BASE}/basename K-KW_TRIGGERS/g" ${FILE_PARAM}
fi

if test -d "${ETG_DIR}"
then
    cd ${ETG_DIR}
    ${CMD_KW} ${FILE_PARAM} -inlist /tmp/kw-${GPS_START}-auto_filelist.txt
else
    echo "Can't find ${ETG_DIR}"
fi

rm -fr /tmp/kw-${GPS_START}-auto_filelist.txt
