#!/bin/bash

# Assume it runs Thursday midnight

startdate=`date -d '-9 day' +%Y-%m-%d`
enddate=`date -d '-2 day' +%Y-%m-%d`
starttime=`tconvert $startdate 17:00:00`
endtime=`tconvert $enddate 8:59:59`

./plotter_burst_3detectors.sh ${starttime}_${endtime}_HVK
./plotter_burst_3detectors.sh ${starttime}_${endtime}_LHK
./plotter_burst_3detectors.sh ${starttime}_${endtime}_LVK

./plotter_burst_4detectors.sh ${starttime}_${endtime}_LHVK
