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
ETG_DIR=/home/controls/triggers
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


################################
### Time epoch
################################
#let GPS_END=`__get_periodic_gps_epoch ${CRON_INTERVAL}`+${OVERLAP}/2
#let GPS_START=${GPS_END}-${CRON_INTERVAL}*60-${OVERLAP}/2

# MARGIN is time margin before and after the processing data.
let MARGIN=${OVERLAP}/2

mkdir -p ${DIR_OUTPUT}

# Using segments file
date=`date -d '9 hours ago 15 minutes ago' '+%Y-%m-%d'`
year=`date -d '9 hours ago 15 minutes ago' '+%Y'`

# Maybe segment should be changed to SCIENCE mode when O4 starts.
### FIXME: it should be given as input arguments of this scripts
###    2021-06-17  changed unlocked segments for investigating Oplev glitches
#segment="/users/DET/tools/Segments/Script/Partial/K1-GRD_LOCKED_SEGMENT_UTC_"$date".txt"
segment="/users/oshino/Segments/Script/tmp/Partial/K1-GRD_LOCKED_SEGMENT_UTC_"$date".txt"

# Loop over segments.
# CAUTION: Bug in treatment of 0:00:00 !!!
# the segment including 0:00:00 maybe separated in segment files. If one of them is shorter than 64 sec, not processed.
# WARNING: MARGIN is different from O3GK configuration. In O3GK configuration, GPS_END is set earlier by 30 sec. 30 sec is determined by burst analysis margin.
cat $segment | while read GPS_START GPS_END
		     
do
    ################################
    ### Execute
    ################################

    GPS_START=$(( $GPS_START - $MARGIN ))
    GPS_END=$(( $GPS_END + $MARGIN ))
    ${CMD_OMICRON} ${GPS_START} ${GPS_END} ${FILE_PARAM}
    echo "GPS_START" $GPS_START
    echo "GPS_END" $GPS_END

done

################################
### Move to LIGO convention
################################
__mv_etg_ligo_convention ${IFO} ${DIR_OUTPUT} ${ETG_DIR}
