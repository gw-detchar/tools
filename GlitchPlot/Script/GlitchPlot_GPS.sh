#!/bin/bash

echo "GlitchPlot_GPS starts running."

# Take argument of event GPS time.
gpstime=$1
#gpstime=1260822812

detection_statistics=-1
rho=-1
reduced_chi_square=-1

#infile=cbc_max_rhohat_ER2.txt
first=true
outfile=parameter.txt

rm -rf $outfile
touch $outfile

#cat $infile | while read gpstime   rho  reduced_chi_square   detection_statistics
#do
#    if "$first"; then
#	first=false
#	continue
#    fi

    #channel=K1:CAL-CS_PROC_C00_STRAIN_DBL_DQ
    #min_duration=0.1
    #max_duration=10
    #bandwidth=1
    #maxSNR=$detection_statistics
    #frequency_SNR=100
    #max_amp=$detection_statistics
    #frequency_amp=100
    #eventtype=graceDB
    #triggertype=graceDB
    #Index=0

    #if [ "$(echo "$reduced_chi_square > 2" | bc)" -eq 1 ]; then
	#continue
    #fi

    #if [ "$(echo "$maxSNR > 5" | bc)" -eq 1 ]; then
	{
	    echo $gpstime $rho $reduced_chi_square $detection_statistics
	    
	} >> $outfile
    #fi
#done

echo $outfile

echo 
./condor_jobfile_CBC.sh $outfile

while :
do
    sleep 60
    echo "check condor."
    condor_q                                                                       
    tmp=`condor_q $USER | grep $USER`
    if [ "${tmp}" = "" ]; then
        echo "condor finished."
        break;
    fi
done

./gene_html_for_GlitchPlot.sh $gpstime
