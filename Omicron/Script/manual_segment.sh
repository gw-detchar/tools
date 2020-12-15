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
let MARGIN=${OVERLAP}/2

# LASTCUT is length to cut the end og the lock segment. [sec]
LASTCUT=30
#LASTCUT=0

mkdir -p ${DIR_OUTPUT}

# Using segments file
segment=$2

cat $segment | while read GPS_START GPS_END
do
    ################################
    ### Execute
    ################################

    echo --------------------------------------------
    duration=$(( $GPS_END - $GPS_START ))

    # To avoid failing job with 60 sec length
    #if [ $duration -lt 60 ]; then
	#GPS_START=$(( $GPS_START - 60 ))
    #fi

    #GPS_START=$(( $GPS_START - $MARGIN ))
    #GPS_END=$(( $GPS_END + $MARGIN ))

    # procedure to avoid skipping data around 0:00:00 for MARGIN and LASTCUT
    hhmmss=`gpstime $GPS_END | grep UTC`
    hhmmss=${hhmmss:17}

    if [ "$hhmmss" = "00:00:00" ]; then
	GPS_END=$(( $GPS_END + $MARGIN ))
    else
	GPS_END=$(( $GPS_END - $LASTCUT ))
    fi

    ${CMD_OMICRON} ${GPS_START} ${GPS_END} ${FILE_PARAM}
    echo "GPS_START" $GPS_START
    echo "GPS_END" $GPS_END

    # Remove marginal file
    #if [ $duration -lt 60 ]; then
	#rm -rf /home/controls/triggers/tmp/K1\:CAL-CS_PROC_DARM_DISPLACEMENT_DQ/*${GPS_START}*
    #fi
done

################################
### Move to LIGO convention
################################
__mv_etg_ligo_convention ${IFO} ${DIR_OUTPUT} ${ETG_DIR}

