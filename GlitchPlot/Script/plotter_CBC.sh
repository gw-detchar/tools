#!/bin/bash

infile=cbc_max_rhohat_ER2.txt
first=true
outfile=parameter.txt

rm -rf $outfile
touch $outfile

cat $infile | while read gpstime   rho  reduced_chi_square   detection_statistics
do
    if "$first"; then
	first=false
	continue
    fi

    channel=K1:CAL-CS_PROC_C00_STRAIN_DBL_DQ
    min_duration=0.1
    max_duration=10
    bandwidth=1
    maxSNR=$detection_statistics
    frequency_SNR=100
    max_amp=$detection_statistics
    frequency_amp=100
    eventtype=CBC
    triggertype=kagalin
    Index=0

    if [ "$(echo "$reduced_chi_square > 2" | bc)" -eq 1 ]; then
	continue
    fi

    if [ "$(echo "$maxSNR > 5" | bc)" -eq 1 ]; then
	{
	    echo $gpstime $channel $min_duration $max_duration $bandwidth $maxSNR $frequency_SNR $max_amp $frequency_amp $eventtype $triggertype $Index
	    
	} >> $outfile
    fi
done

echo $outfile

./condor_jobfile_CBC.sh $outfile
