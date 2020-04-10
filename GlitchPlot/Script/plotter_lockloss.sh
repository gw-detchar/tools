#!/bin/bash

cd /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script

list=( `find /home/detchar/git/kagra-detchar/tools/Segments/Script/Partial/K1-GRD_LOCKED_SEGMENT_UTC_*.xml` )

date="`date +"%Y%m%d"`"
mkdir /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/log/${date}

# This script will run every 3 hours.
jst_end="`date +"%Y-%m-%d %H:00:00"`"

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

GPSEND=`${cmd_gps} ${jst_end}| head -3 | tail -1 | awk '{printf("%d\n", $2)}'`
let GPSSTART=${GPSEND}-10800

gpstime ${GPSSTART}

for file in ${list[@]};do
    echo python plotter_lockloss.py -i ${file} -s ${GPSSTART} -d 10800 -l Observation
    python plotter_lockloss.py -i ${file} -s ${GPSSTART} -d 10800 -l Observation
done

condor_submit job_lockloss_suggestion.sdf
condor_submit job_lockloss_qtransform.sdf
condor_submit job_lockloss_coherencegram.sdf
condor_submit job_lockloss_lock.sdf
condor_submit job_lockloss_spectrogram.sdf
condor_submit job_lockloss_spectrum.sdf
condor_submit job_lockloss_time.sdf
