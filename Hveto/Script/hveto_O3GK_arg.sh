#!/bin/bash
#
#        Author: Chihiro Kozakai, Shoichi Oshino
# Last Modified: 2020/05/21
#

DIRNAME_DATE=$1
#DIRNAME_DATE=2020-04-15

# Kamioka
if [ $USER == "controls" ]; then

    # conda environment must be set before running this script.
    #conda activate ligo-summary-3.7

    a=`gpstime ${DIRNAME_DATE} 9:00:00 | grep GPS`

    GPSSTART=${a#*GPS: }
    GPSSTART=${GPSSTART:0:10}
    GPSEND=`expr $GPSSTART + 86400`

    echo $GPSSTART
    echo $GPSEND

    #SEGMENTFILE=/users/DET/Segments/SegmentList_FPMI_UTC_$3.xml
    #SEGMENTFILE=`ls /users/DET/Segments/K1-GRD_SCIENCE_MODE/*/K1-GRD_SCIENCE_MODE_SEGMENT_UTC_$3.xml`
    # Temporary setting for GRB200415
    #SEGMENTFILE=`ls /users/DET/Segments/K1-GRD_LOCKED/*/K1-GRD_LOCKED_SEGMENT_UTC_$3.xml`
    #SEGMENTFILE=/users/DET/Segments/K1-GRD_LOCKED/2020/K1-GRD_LOCKED_SEGMENT_UTC_${DIRNAME_DATE}.xml
    #SEGMENTFILE=/users/DET/tools/Segments/Script/science_SEGMENT_UTC_2020-04-15.xml
    #SEGMENTFILE=/users/DET/Segments/K1-DET_FOR_GRB200415A/2020/K1-DET_FOR_GRB200415A_UTC_${DIRNAME_DATE}.xml
    SEGMENTFILE=/users/DET/Segments/K1-DET_FOR_GRB200415A/2020/K1-DET_FOR_GRB200415A_UTC_${DIRNAME_DATE}.xml

    if [ "${DIRNAME_DATE}" = "2020-04-15" ]; then
	INIFILE=/users/DET/tools/Hveto/etc/O3GKC20_0415.ini
    else
	#INIFILE=/users/DET/tools/Hveto/etc/manual.ini
	#INIFILE=/users/DET/tools/Hveto/etc/burst.ini
	#INIFILE=/users/DET/tools/Hveto/etc/burst_O3.ini
	#INIFILE=/users/DET/tools/Hveto/etc/O3GK.ini
	#INIFILE=/users/DET/tools/Hveto/etc/O3GK_shortlist1.ini
	#INIFILE=/users/DET/tools/Hveto/etc/O3GK_shortlist2.ini
	#INIFILE=/users/DET/tools/Hveto/etc/O3GK_shortlist1_ver2.ini
	#INIFILE=/users/DET/tools/Hveto/etc/O3GKC20_shortlist${n}.ini
	INIFILE=/users/DET/tools/Hveto/etc/O3GKC20.ini
	#INIFILE=/users/DET/tools/Hveto/etc/O3GKC20_0415_KISTI.ini
	#INIFILE=/users/DET/tools/Hveto/etc/O3GK_test.ini
    fi
    
    OUTPUTDIR=/home/controls/public_html/hveto/manual/test/${DIRNAME_DATE}_kisti_${GPSSTART}_${GPSEND}_20210318

# Kashiwa    
else

    source /gpfs/ligo/sw/conda/etc/profile.d/conda.sh
    conda activate igwn-py38

    a=`gpstime "${DIRNAME_DATE} 9:00:00" | grep GPS`

    GPSSTART=${a#*GPS: }
    GPSSTART=${GPSSTART:0:10}
    GPSEND=`expr $GPSSTART + 86400`

    echo $GPSSTART
    echo $GPSEND

    SEGMENTFILE=/home/detchar/Segments/K1-DET_FOR_GRB200415A/2020/K1-DET_FOR_GRB200415A_UTC_${DIRNAME_DATE}.xml

    if [ "${DIRNAME_DATE}" = "2020-04-15" ]; then
	INIFILE=/home/detchar/git/kagra-detchar/tools/Hveto/etc/O3GKC20_0415.ini
    else
	INIFILE=/home/detchar/git/kagra-detchar/tools/Hveto/etc/O3GKC20.ini
    fi
    
    OUTPUTDIR=/home/detchar/hveto/manual/test/${DIRNAME_DATE}_C20_${GPSSTART}_${GPSEND}_20210304
fi

#export PATH=/home/controls/bin/miniconda2/envs/test/bin:$PATH
#export LIGO_DATAFIND_SERVER=10.68.10.85:80

#EXEC : path to hveto
EXEC=hveto

hveto -V

IFO='K1'
#DIRNAME_DATE=$3






# Number of Process
#NPROCESS=10
NPROCESS=1
# Number of Omega Scans
NOMEGA=5


#OUTPUTLOG=/home/controls/public_html/hveto/logs/manual_hveto-${DIRNAME_DATE}.log

#Hveto run
echo ${EXEC} ${GPSSTART} ${GPSEND} --ifo ${IFO} --config-file ${INIFILE} --output-directory ${OUTPUTDIR} --analysis-segments ${SEGMENTFILE} --nproc ${NPROCESS} --omega-scans ${NOMEGA}

${EXEC} ${GPSSTART} ${GPSEND} --ifo ${IFO} --config-file ${INIFILE} --output-directory ${OUTPUTDIR} --analysis-segments ${SEGMENTFILE} --nproc ${NPROCESS} --omega-scans ${NOMEGA}




#&> ${OUTPUTLOG}

#hveto 1262304018 1262390418 --ifo K1 --config-file /users/DET/tools/Hveto/etc/k1-hveto-daily-o3.ini --output-directory /home/controls/public_html/hveto/day/20200106 --analysis-segments /users/DET/Segments/SegmentList_FPMI_UTC_2020-01-06.xml --nproc 10 --omega-scans 5
