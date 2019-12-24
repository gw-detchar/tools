#!/bin/bash

#infile=ER2_triggers_cWB.txt
#infile=burst/EVENTS_HVK.txt
infile=burst/EVENTS_LHVK.txt
first=true
outfile=parameter.txt

rm -rf $outfile
touch $outfile

#cat $infile | while read Index   Det     SNR             hrss            S_t                     C_t             C_f             BW              duration
#cat $infile | while read passed dump rho cc01 cc2 cc3 camp tshift tsshift lh pf ed C_f BW duration npixel fres cwb tH tV tK SNRH SNRV SNRK hrssH hrssV hrssK phi theta psi
cat $infile | while read passed dump rho cc01 cc2 cc3 camp tshift tsshift lh pf ed C_f BW duration npixel fres cwb tL tH tV tK SNRL SNRH SNRV SNRK hrssL hrssH hrssV hrssK phi theta psi
do
    #if "$first"; then
	#first=false
	#continue
    #fi
    if [ $passed = "#" ]; then
	continue
    fi

    #if [ "$duration" = "" ]; then
#	continue
    #fi


    #gpstime=`echo $S_t | sed -e 's/J1_//g'`
    gpstime=$tK
    #channel=K1:LSC-POP_PDA1_RF17_Q_ERR_DQ
    channel=K1:CAL-CS_PROC_DARM_DISPLACEMENT_DQ
    min_duration=$duration
    max_duration=$duration
    bandwidth=$BW
    #maxSNR=$SNR
    maxSNR=$SNRK
    frequency_SNR=$C_f
    #max_amp=$hrss
    max_amp=$hrssK
    frequency_amp=$C_f
    eventtype=Burst
    triggertype=cWB

#    if [ "$(echo "$maxSNR > 23" | bc)" -eq 1 ]; then
    {
	echo $gpstime $channel $min_duration $max_duration $bandwidth $maxSNR $frequency_SNR $max_amp $frequency_amp $eventtype $triggertype $Index
	
    } >> $outfile
#    fi
done

echo $outfile

./condor_jobfile_plotter.sh $outfile
