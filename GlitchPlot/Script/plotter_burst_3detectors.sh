#!/bin/bash

var=$1
url="http://157.82.231.182/~ctsweb/IO1_"$var"/M1.R_rMRA_i0cc00_i0rho0_freq16_2048/data/EVENTS.txt"
infile="burst/EVENTS_"$var".txt"
first=true
outfile="burst/"$var"_parameter.txt"

#curl $url > $infile

rm -rf $outfile
touch $outfile

count=0

# ER2
#cat $infile | while read Index   Det     SNR             hrss            S_t                     C_t             C_f             BW              duration
# HVK 3 detector
cat $infile | while read passed dump rho cc01 cc2 cc3 camp tshift tsshift lh pf ed C_f BW duration npixel fres cwb tH tV tK SNRH SNRV SNRK hrssH hrssV hrssK phi theta psi
# ER3 3 detector
#cat $infile | while read passed dump rho cc01 cc2 cc3 camp tshift tsshift lh pf ed C_f BW duration npixel fres cwb tH tV tK SNRH SNRV SNRK hrssH hrssV hrssK phi theta psi
# ER3 3 detector
#cat $infile | while read passed dump rho cc01 cc2 cc3 camp tshift tsshift lh pf ed C_f BW duration npixel fres cwb tH tV tK SNRH SNRV SNRK hrssH hrssV hrssK phi theta psi
#ER3 4 detector
#cat $infile | while read passed dump rho cc01 cc2 cc3 camp tshift tsshift lh pf ed C_f BW duration npixel fres cwb tL tH tV tK SNRL SNRH SNRV SNRK hrssL hrssH hrssV hrssK phi theta psi
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

    
    count=$(( $count + 1 ))

    #gpstime=`echo $S_t | sed -e 's/J1_//g'`
    gpstime=$tK
    #channel=K1:LSC-POP_PDA1_RF17_Q_ERR_DQ
    channel=K1:CAL-CS_PROC_DARM_DISPLACEMENT_DQ
    #channel=K1:CAL-CS_PROC_C00_STRAIN_DBL_DQ
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
    Index=$count

    peakQ=`echo "scale=5; $C_f * $duration " | bc` 


    peakQ_amp=$hrssK
    minf=$(( $C_f - $bandwidth ))
    maxf=$(( $C_f + $bandwidth ))


    tmp=(${SNRK//e/ })
    orderSNRK=${tmp[1]}

    echo SNRK is $SNRK
    echo orderSNRK is $orderSNRK

    if [ "$tshift" = "0" ]; then
	#echo ok
    {
	echo $gpstime $channel $min_duration $max_duration $bandwidth $maxSNR $frequency_SNR $max_amp $frequency_amp $eventtype $triggertype $Index $peakQ $peakQ_amp $minf $maxf
	
    } >> $outfile
    fi

    #if [ "$(echo "$orderSNRK >= -2" | bc)" -eq 1 ]; then
	#echo SNRK is $SNRK
    #{
	#echo $gpstime $channel $min_duration $max_duration $bandwidth $maxSNR $frequency_SNR $max_amp $frequency_amp $eventtype $triggertype $Index $peakQ $peakQ_amp $minf $maxf
	
    #} >> $outfile
    #fi

    #if [ ${tmp[0]} != "0.0" ] && [  "$orderSNRK" = "+00" ]; then
	#echo ok
    #{
	#echo $gpstime $channel $min_duration $max_duration $bandwidth $maxSNR $frequency_SNR $max_amp $frequency_amp $eventtype $triggertype $Index $peakQ $peakQ_amp $minf $maxf
	
    #} >> $outfile
    #fi

done

echo $outfile

./condor_jobfile_plotter.sh $outfile
