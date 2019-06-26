#!/bin/bash

# input trigger file
#inputtriggerfile="K1-IMC_CAV_ERR_OUT_DQ_OMICRON-1241900058-60.xml.gz"
#inputtriggerfile="K1-IMC_CAV_REFL_OUT_DQ_OMICRON-1242713238-60.xml.gz"
# output parameter txt file
#parameterlist="parameter.txt"

# Get time to process. The time is when omicron output is made.
# Use the last quarter hour.
#

cd /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/

INTERVAL=15

#let mm=`date +"%M"`/${INTERVAL}*${INTERVAL}
let mm=`date +"%M" | sed -e "s/^0//"`/${INTERVAL}*${INTERVAL}


jst_end="`date +"%Y-%m-%d %H:${mm}:00"`"

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

GPS_END=`${cmd_gps} ${jst_end}| head -3 | tail -1 | awk '{printf("%d\n", $2)}'`

let GPS_START=${GPS_END}-${INTERVAL}*60

jst_start=`${cmd_gps} ${GPS_START}| head -1`
jst_start=${jst_start#*:}

let GPS_START=${GPS_END}-${INTERVAL}*60

echo $jst_start
echo $jst_end
echo $GPS_START
echo $GPS_END


let tmp=${GPS_END:0:5}-1
#echo $tmp

list=()

today=`date +%Y%m%d`
yesterday=`date --date 'a day ago' +%Y%m%d`
list+=( `find /home/chihiro.kozakai/public_html/KAGRA/GlitchPlot/parameter/$today/* -newermt "$jst_start" -and ! -newermt "$jst_end"` `find /home/chihiro.kozakai/public_html/KAGRA/GlitchPlot/parameter/$yesterday/* -newermt "$jst_start" -and ! -newermt "$jst_end"`  )



for file in ${list[@]};do
    
    if [ -d $file ]; then
	continue
    fi
    
    echo $file
    
    echo "----------plot job throwing----------"
    # from the plot parameter, throw condor job to make basic plots.
    ./condor_jobfile_plotter.sh $file
    
done



