#!/bin/bash

# Assume it runs Thursday midnight

gpstime

startdate=`date -d '-9 day' +%Y-%m-%d`
enddate=`date -d '-3 day' +%Y-%m-%d`
enddateJST=`date -d '-2 day' +%Y-%m-%d`
starttime=`tconvert $startdate 8:00:00`
endtime=`tconvert $enddate 23:59:59`

echo $starttime
echo $endtime

/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/plotter_burst_3detectors.sh ${starttime}_${endtime}_HVK
/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/plotter_burst_3detectors.sh ${starttime}_${endtime}_LHK
/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/plotter_burst_3detectors.sh ${starttime}_${endtime}_LVK

/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/plotter_burst_4detectors.sh ${starttime}_${endtime}_LHVK

while :
do
    sleep 60
    echo "check condor."
    tmp=`condor_q | grep chihiro`
    if [ "${tmp}" = "" ]; then
        echo "condor finished."
	gpstime
        break;
    fi
done

{
    echo "From: ckozakai <ckozakai@icrr.u-tokyo.ac.jp>"
    echo "To: ckozakai <ckozakai@icrr.u-tokyo.ac.jp>"
    echo "Subject: Please reprocess Yuzu summary page"
    echo ""
    echo "Yuzurihara-sama,"
    echo ""
    echo "Please reprocess Yuzu summary page during last week."
    echo "From " $startdate " to " $enddateJST "."
    echo ""
    echo "Best,"
    echo "Chihiro Kozakai"
} | sendmail -i -t
