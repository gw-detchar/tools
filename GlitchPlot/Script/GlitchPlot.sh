#!/bin/bash

# input trigger file
#inputtriggerfile="K1-IMC_CAV_ERR_OUT_DQ_OMICRON-1241900058-60.xml.gz"
#inputtriggerfile="K1-IMC_CAV_REFL_OUT_DQ_OMICRON-1242713238-60.xml.gz"
# output parameter txt file
#parameterlist="parameter.txt"

# Get time to process. The time is when omicron output is made.
# Use the last quarter hour.
#

if [ $USER == "controls" ]; then
    kamioka=true
else
    kamioka=false
fi

if "${kamioka}"; then
    workdir=/users/DET/tools/GlitchPlot/Script
else
    workdir=/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/
fi

cd $workdir
    
INTERVAL=15

#let mm=`date +"%M"`/${INTERVAL}*${INTERVAL}
let mm=`date +"%M" | sed -e "s/^0//"`/${INTERVAL}*${INTERVAL}


jst_end="`date +"%Y-%m-%d %H:${mm}:00"`"

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

#GPS_END=`${cmd_gps} ${jst_end}| head -3 | tail -1 | awk '{printf("%d\n", $2)}'`
GPS_END=`tconvert -l $jst_end`

let GPS_START=${GPS_END}-${INTERVAL}*60

#jst_start=`${cmd_gps} ${GPS_START}| head -1`
#jst_start=${jst_start#*:}
jst_start=`tconvert -l -f "%Y-%m-%d %H:%M:%S" $GPS_START`

echo $jst_start
echo $jst_end
echo $GPS_START
echo $GPS_END


let tmp=${GPS_END:0:5}-1
#echo $tmp

list=()

today=`date +%Y%m%d`
yesterday=`date --date '1 day ago' +%Y%m%d`
echo $today
echo $yesterday

if "${kamioka}"; then
    list+=( `find /users/DET/Result/GlitchPlot/parameter/$today/* -newermt "$jst_start" -and ! -newermt "$jst_end"` `find /users/DET/Result/GlitchPlot/parameter/$yesterday/* -newermt "$jst_start" -and ! -newermt "$jst_end"`  )
else
    list+=( `find /home/chihiro.kozakai/public_html/KAGRA/GlitchPlot/parameter/$today/* -newermt "$jst_start" -and ! -newermt "$jst_end"` `find /home/chihiro.kozakai/public_html/KAGRA/GlitchPlot/parameter/$yesterday/* -newermt "$jst_start" -and ! -newermt "$jst_end"`  )
fi

for file in ${list[@]};do
    
    if [ -d $file ]; then
	continue
    fi
    
    echo $file
    
    echo "----------plot job throwing----------"
    # from the plot parameter, throw condor job to make basic plots.
    #./condor_jobfile_plotter.sh $file
    $workdir/condor_jobfile_plotter.sh $file
    
done

$workdir/makelink.sh $today
$workdir/makelink.sh $yesterday
#condor_release chihiro.kozakai

#Job re-submission
#./auto_successcheck.sh

