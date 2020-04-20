#!/bin/bash
#******************************************#
#     File Name: Omicron/automation.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/31 16:23:58
#******************************************#

################################
### Set variable
################################
DET_ROOT=/users/DET
DET_OMICRON=${DET_ROOT}/tools/Omicron
FILE_PARAM=${DET_OMICRON}/Parameter/test.txt
CMD_OMICRON=/home/controls/opt/virgosoft/Omicron/v2r3/Linux-x86_64/omicron.exe
CRON_INTERVAL=15 # Need to match the interval of omicron on the cron job. [min.]
#ETG_DIR=/home/controls/triggers
ETG_DIR=/users/DET/tools/Omicron/Script/test
IFO=K1

################################
### Omicron parameter
################################
if test -e "${1}"
then
    FILE_PARAM=${1}
    STR_PARAM=`cat ${1}`
    printf ""
else
    STR_PARAM=`cat <<EOF | tee ${FILE_PARAM}
DATA FFL ${DET_ROOT}/Cache/latest.ffl
DATA CHANNELS K1:IMC-MCL_SERVO_OUT_DQ
DATA SAMPLEFREQUENCY 2048

PARAMETER TIMING 64 4
PARAMETER FREQUENCYRANGE 10 1024
PARAMETER QRANGE 4 100
PARAMETER MISMATCHMAX 0.2
PARAMETER SNRTHRESHOLD 6
PARAMETER PSDLENGTH 128

OUTPUT DIRECTORY /home/controls/triggers/tmp
OUTPUT PRODUCTS triggers
OUTPUT FORMAT xml
OUTPUT VERBOSITY 0
EOF`
fi

###################################################################################################
###################################################################################################
###   Don't touch below
###################################################################################################
###################################################################################################
source ${DET_OMICRON}/Script/functions.sh
DIR_OUTPUT=`printf "${STR_PARAM}" | grep "OUTPUT DIRECTORY " | awk '{print $3}'`
OVERLAP=`printf "${STR_PARAM}" | grep "PARAMETER TIMING " | awk '{print $4}'`

echo DIR_OUTPUT $DIR_OUTPUT
################################
### Time epoch
################################

#let GPS_START=1261070416
#let GPS_END=1261070960
#let GPS_START=1261070056
#let GPS_END=1261070960
#let GPS_START=1261069456
#let GPS_END=1261070360
#let GPS_START=1261069516
#let GPS_END=1261070420
#let GPS_START=1261070356
#let GPS_END=1261071260
#let GPS_START=1261070366
#let GPS_END=1261071270
#let GPS_START=1261070336
#let GPS_END=1261071240
#let GPS_START=1261070327
#let GPS_END=1261070392
let GPS_START=1271166316
let GPS_END=1271167220

################################
### Execute
################################
mkdir -p ${DIR_OUTPUT}
${CMD_OMICRON} ${GPS_START} ${GPS_END} ${FILE_PARAM}

################################
### Move to LIGO convention
################################
#__mv_etg_ligo_convention ${IFO} ${DIR_OUTPUT} ${ETG_DIR}
