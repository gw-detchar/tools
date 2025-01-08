#!/bin/bash
#
#        Author: Chihiro Kozakau, Shoichi Oshino
# Last Modified: 2020/05/21
#

#conda activate ligo-summary-3.7

#export PATH=/home/controls/bin/miniconda2/envs/test/bin:$PATH
export LIGO_DATAFIND_SERVER=10.68.10.85:80

#EXEC : path to hveto
EXEC=hveto

hveto -V
#1/1
#GPSSTART=1261920618
#GPSEND=1261924218
#SEGMENTFILE=/users/DET/tools/Segments/Script/tmp/Partial/2020/K1-GRD_SCIENCE_MODE_SEGMENT_UTC_2020-01-01.xml

#GPSSTART=$1
#GPSEND=$2

# Around GRB200415A
#GPSSTART=1270975483
#GPSEND=1270975991
#DIRNAME_DATE=2020-04-15

# Around GRB200415A, 3hours with consistent IFO configuration
#GPSSTART=1270974975
#GPSEND=1270987464
#DIRNAME_DATE=2020-04-15

# Whole day on 2020/4/15
#GPSSTART=1270944018
#GPSEND=1271030418
#DIRNAME_DATE=2020-04-15

# Whole day on 2020/4/8
#GPSSTART=1270339218
#GPSEND=1270425618
#DIRNAME_DATE=2020-04-08

# Whole day on 2020/4/11
#GPSSTART=1270598418
#GPSEND=1270684818
#DIRNAME_DATE=2020-04-11

# Partial day on 2020/4/10
#GPSSTART=1270512018
#GPSEND=1270598418
#GPSSTART=1270525300
#GPSEND=1270525334
#DIRNAME_DATE=2020-04-10

# Partial day on 2020/4/20
#GPSSTART=1271376018
#GPSEND=1271462418
#GPSSTART=1271459312
GPSSTART=1271380808
GPSEND=1271380868
DIRNAME_DATE=2020-04-20

#SEGMENTFILE=/users/DET/Segments/SegmentList_FPMI_UTC_$3.xml
#SEGMENTFILE=`ls /users/DET/Segments/K1-GRD_SCIENCE_MODE/*/K1-GRD_SCIENCE_MODE_SEGMENT_UTC_$3.xml`
# Temporary setting for GRB200415
#SEGMENTFILE=`ls /users/DET/Segments/K1-GRD_LOCKED/*/K1-GRD_LOCKED_SEGMENT_UTC_$3.xml`
#SEGMENTFILE=/users/DET/Segments/K1-GRD_LOCKED/2020/K1-GRD_LOCKED_SEGMENT_UTC_${DIRNAME_DATE}.xml
#SEGMENTFILE=/users/DET/tools/Segments/Script/science_SEGMENT_UTC_2020-04-15.xml
SEGMENTFILE=/users/DET/Segments/K1-SCIENCE_MODE/2020/K1-SCIENCE_MODE_SEGMENT_UTC_2020-04-20.xml

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
#INIFILE=/users/DET/tools/Hveto/etc/burst.ini
#INIFILE=/users/DET/tools/Hveto/etc/burst_O3.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GK.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GK_shortlist1.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GK_shortlist2.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GK_shortlist1_ver2.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GKC20_shortlist1_test2.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GKC20.ini
INIFILE=/users/DET/tools/Hveto/etc/tmp.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GKC20_shortlist2.ini
#INIFILE=/users/DET/tools/Hveto/etc/O3GK_test.ini
#DIRNAME_DATE=$3

OUTPUTDIR=/home/controls/public_html/hveto/manual/test/${DIRNAME_DATE}_C20_${GPSSTART}_${GPSEND}_20201230_test



# Number of Process
#NPROCESS=10
NPROCESS=1
# Number of Omega Scans
NOMEGA=5


#OUTPUTLOG=/home/controls/public_html/hveto/logs/manual_hveto-${DIRNAME_DATE}.log

#Hveto run
${EXEC} ${GPSSTART} ${GPSEND} --ifo ${IFO} --config-file ${INIFILE} --output-directory ${OUTPUTDIR} --analysis-segments ${SEGMENTFILE} --nproc ${NPROCESS} --omega-scans ${NOMEGA}

#&> ${OUTPUTLOG}

#hveto 1262304018 1262390418 --ifo K1 --config-file /users/DET/tools/Hveto/etc/k1-hveto-daily-o3.ini --output-directory /home/controls/public_html/hveto/day/20200106 --analysis-segments /users/DET/Segments/SegmentList_FPMI_UTC_2020-01-06.xml --nproc 10 --omega-scans 5
