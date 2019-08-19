#!/bin/bash

infile=ER2_triggers_cWB.txt
first=true
outfile=parameter.txt

rm -rf $outfile
touch $outfile

cat $infile | while read Index   Det     SNR             hrss            S_t                     C_t             C_f             BW              duration
do
    if "$first"; then
	first=false
	continue
    fi

    if [ "$duration" = "" ]; then
	continue
    fi


    gpstime=`echo $S_t | sed -e 's/J1_//g'`
    channel=K1:LSC-POP_PDA1_RF17_Q_ERR_DQ
    min_duration=$duration
    max_duration=$duration
    bandwidth=$BW
    maxSNR=$SNR
    frequency_SNR=$C_f
    max_amp=$hrss
    frequency_amp=$C_f
    eventtype=Burst
    triggertype=cWB

    if [ "$(echo "$maxSNR > 23" | bc)" -eq 1 ]; then
	{
	    echo $gpstime $channel $min_duration $max_duration $bandwidth $maxSNR $frequency_SNR $max_amp $frequency_amp $eventtype $triggertype $Index
	    
	} >> $outfile
    fi
done

echo $outfile

./condor_jobfile_plotter.sh $outfile
