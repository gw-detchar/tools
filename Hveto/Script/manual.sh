#!/bin/bash
#
#        Author: Chihiro Kozakau
# Last Modified: 2019/01/07
#

export PATH=/home/controls/bin/miniconda2/envs/test/bin:$PATH
export LIGO_DATAFIND_SERVER=10.68.10.85:80

#EXEC : path to hveto
EXEC=hveto

#1/1
#GPSSTART=1261920618
#GPSEND=1261924218
#SEGMENTFILE=/users/DET/tools/Segments/Script/tmp/Partial/2020/K1-GRD_SCIENCE_MODE_SEGMENT_UTC_2020-01-01.xml

GPSSTART=$1
GPSEND=$2
#SEGMENTFILE=/users/DET/Segments/SegmentList_FPMI_UTC_$3.xml
#SEGMENTFILE=`ls /users/DET/Segments/K1-GRD_SCIENCE_MODE/*/K1-GRD_SCIENCE_MODE_SEGMENT_UTC_$3.xml`
# Temporary setting for GRB200415
SEGMENTFILE=`ls /users/DET/Segments/K1-GRD_LOCKED/*/K1-GRD_LOCKED_SEGMENT_UTC_$3.xml`

echo $GPSSTART
echo $GPSEND
echo $SEGMENTFILE
#12/17
#GPSSTART=1260604818
#GPSEND=1260662418
#SEGMENTFILE=/users/DET/Segments/SegmentList_FPMI_UTC_2019-12-17.xml
# burst test
#GPSSTART=1260759400
#GPSEND=1260759460
#GPSEND=1260795400
#SEGMENTFILE=/users/DET/Segments/SegmentList_FPMI_UTC_2019-12-19.xml

IFO='K1'
#INIFILE=/users/DET/tools/Hveto/etc/manual.ini
INIFILE=/users/DET/tools/Hveto/etc/burst.ini
DIRNAME_DATE=$3
OUTPUTDIR=/home/controls/public_html/hveto/manual/${DIRNAME_DATE}_burst



# Number of Process
NPROCESS=10
# Number of Omega Scans
NOMEGA=5


#OUTPUTLOG=/home/controls/public_html/hveto/logs/manual_hveto-${DIRNAME_DATE}.log

#Hveto run
${EXEC} ${GPSSTART} ${GPSEND} --ifo ${IFO} --config-file ${INIFILE} --output-directory ${OUTPUTDIR} --analysis-segments ${SEGMENTFILE} --nproc ${NPROCESS} --omega-scans ${NOMEGA}

#&> ${OUTPUTLOG}

#hveto 1262304018 1262390418 --ifo K1 --config-file /users/DET/tools/Hveto/etc/k1-hveto-daily-o3.ini --output-directory /home/controls/public_html/hveto/day/20200106 --analysis-segments /users/DET/Segments/SegmentList_FPMI_UTC_2020-01-06.xml --nproc 10 --omega-scans 5
