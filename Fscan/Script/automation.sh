#!/bin/bash
#******************************************#
#     File Name: Fscan/automation.sh
#        Author: Takahiro Yamamoto, Shoichi Oshino
# Last Modified: 2019/12/12 8:44
#******************************************#

################################
### Set variable
################################
if test `whoami` = "controls"
then
    DET_ROOT=/users/DET
    DIR_SEG=${DET_ROOT}/Segments
else
    DET_ROOT=${HOME}/git/kagra-detchar
    DIR_SEG=${HOME}/segment/UTC
fi
DET_FSCAN=${DET_ROOT}/tools/Fscan
DIR_FSCAN=${HOME}/opt/Fscan
FILE_RSC=${DIR_FSCAN}/KagraDailyFscanGenerator.rsc
CMD_GPSTIME=${HOME}/bin/gpstime
CMD_SEGGEN=${DET_ROOT}/tools/Segments/Script/makeDailySegment.py
CMD_FSCAN=${DIR_FSCAN}/multiFscanGenerator_kagra.tcl
CMD_LINK=${DET_FSCAN}/Script/fscanSummLink.sh

###################################################################################################
###################################################################################################
###   Don't touch below
###################################################################################################
###################################################################################################
source ${DET_FSCAN}/etc/environment.sh

################################
### Get Time
################################
JST_DATE=`date --date '1 day ago' +"%Y-%m-%d"`
GPS_START=`${CMD_GPSTIME} ${JST_DATE} 09:00:00 | grep GPS | awk '{print $2}'`
let GPS_END=${GPS_START}+86400

echo "==> LOCAL: ${JST_DATE}"
echo "==> START: ${GPS_START}"
echo "==>   END: ${GPS_END}"
FILE_SEG=${DIR_SEG}/SegmentList_IMC_UTC_${JST_DATE}.txt

################################
### Generate Resource File
################################
cat <<EOF > ${FILE_RSC}
set ::masterList {\\
{K1:CAL-CS_PROC_MICH_DISPLACEMENT_DQ ADC_REAL4 K1 K1_C default none 0 0 0 1800 0 5000 100 32 0.25 default}\\
{K1:CAL-CS_PROC_DARM_DISPLACEMENT_DQ ADC_REAL4 K1 K1_C default none 0 0 0 1800 0 5000 100 32 0.25 default}\\
{K1:CAL-CS_PROC_IMC_FREQUENCY_DQ ADC_REAL4 K1 K1_C default none 0 0 0 1800 0 5000 100 32 0.25 default}\\
{K1:CAL-CS_PROC_C00_STRAIN_DBL_DQ ADC_REAL8 K1 K1_C default none 0 0 0 1800 0 5000 100 32 0.25 default}\\
}

set fixedComparison 0;
set fixedComparisonChanDir "";
set fixedComparisonString "";
set fixedComparisonSNR  0;

set fscanDriverPath "${HOME}/opt/Fscan/fscanDriver_kagra.py"; # complete path to fscanDriver.py
#set matlabPath "/ldcg/matlab_r2008a";      # Path to matlab installation to use with -m option to fscanDriver.py, e.g., /ldcg/matlab_r2008a

set parentOutputDirectory "${HOME}/public_html/fscan/daily";

set startTime "${GPS_START}";
set timeLag 7200;
set endTime "${GPS_END}";

set useEndTimeForDirName 1;    # 0 == false, 1 == true; Use start time to name output directory.

set intersectData 0; # 0 == false, 1 == true; if true run fscanDriver.py with -I option so that it intersects the segments with the times data exists.

set useLSCsegFind 0
set typeLSCsegFind "K1:GRD-PMC_OK"; #Give as a list for each IFO in the masterList
set ::grepCommandAndPath /bin/grep
set ::ligolwPrintCommandAndPath /usr/bin/ligolw_print
EOF

################################
### Execute
################################
printf "==>  LINK: \n"
${CMD_LINK}

printf "==>   SEG: "
if test ! -e ${FILE_SEG}
then
    echo "${CMD_SEGGEN}"
    PATH=${PATH}:${HOME}/bin ${CMD_SEGGEN}
else
    echo "nothing to be done."
fi

cd ${DIR_FSCAN}
printf "==>  FSCAN: "
${CMD_FSCAN} ${FILE_RSC} ${FILE_SEG} -R

