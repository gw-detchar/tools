#!/bin/bash
#
#        Author: Shoichi Oshino
# Last Modified: 2019/12/17
#

export LIGONDSIP=k1nds2
export NDSSERVER=k1nds2:8088,k1nds1:8088,k1nds0:8088
export PATH=/home/controls/bin/miniconda2/envs/ligo-summary-3.7/bin:$PATH
#export PATH=/home/controls/bin/miniconda2/envs/test/bin:$PATH
export LIGO_DATAFIND_SERVER=10.68.10.85:80
#export PYTHONPATH=/home/controls/bin/miniconda2/env/test:$PYTHONPATH

VALUE_DATE=yesterday

usage_exit() {
        echo "Usage: $0 [-d 20200101] " 1>&2
        exit 1
}

while getopts d:h OPT
do
    case $OPT in
        d)  VALUE_DATE=$OPTARG
            DATE_FLAG=true
            ;;
        h)  usage_exit
            ;;
        \?) usage_exit
            ;;
    esac
done

shift $((OPTIND - 1))

DATE=`date -d $VALUE_DATE "+%Y-%m-%d"`
YEAR=`date -d $VALUE_DATE "+%Y"`
DIRNAME_DATE=`date -d $VALUE_DATE "+%Y%m%d"`
GPSSTART=$(lalapps_tconvert $DATE)
DURATION=86400
GPSEND=$(( $GPSSTART + $DURATION ))
IFO='K1'

# Number of Process
NPROCESS=10
# Number of Omega Scans
NOMEGA=10

#Hveto run
#EXEC : path to hveto
EXEC=hveto
INIFILE=/users/DET/tools/Hveto/etc/k1-hveto-daily-o4b.ini
#INIFILE=/users/DET/tools/Hveto/etc/k1-hveto-IMC.ini
OUTPUTDIR=/home/controls/public_html/hveto/day/${DIRNAME_DATE}
#SEGMENTFILE=/users/DET/Segments/K1-GRD_SCIENCE_MODE/2022/K1-GRD_SCIENCE_MODE_SEGMENT_UTC_${DATE}.xml
SEGMENTFILE=/users/DET/Segments/K1-GRD_LOCKED/${YEAR}/K1-GRD_LOCKED_SEGMENT_UTC_${DATE}.xml
OUTPUTLOG=/home/controls/public_html/hveto/logs/daily_hveto-${DIRNAME_DATE}.log
${EXEC} ${GPSSTART} ${GPSEND} --ifo ${IFO} --config-file ${INIFILE} --output-directory ${OUTPUTDIR} --analysis-segments ${SEGMENTFILE} --nproc ${NPROCESS} --omega-scans ${NOMEGA} &> ${OUTPUTLOG}
