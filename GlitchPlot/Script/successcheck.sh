#!/bin/bash

date=20190811

#if "${kamioka}"; then
#    Kozapy="/users/DET/tools/GlitchPlot/Script/Kozapy/samples"
#else
Kozapy="/home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples"
#fi

#list=( `find log/${date}/1736*.out `)
list=( `find log/${date}/103065*.out `)
#list=( `find log/20190713/10220*.out  ` )
#list=( `find log/20190608/out_45660* -newermt "2019-06-29 08:45:00"` )
echo ${list[@]}

#outsdf=retry_$(basename $insdf)
outsdftime=retry_timeseries.sdf
outsdfspectrum=retry_spectrum.sdf
outsdfspectrogram=retry_spectrogram.sdf
outsdfcoherence=retry_coherencegram.sdf
outsdfqtrans=retry_qtransform.sdf
outsdflock=retry_lock.sdf

# Write a file for condor submission.                                                                            
runlock="$PWD/run_lock.sh"
pylock="$Kozapy/batch_locksegment.py"
{
    echo "PWD = $Fp(SUBMIT_FILE)"
    echo "transfer_input_files = rm_if_empty.sh"
    echo '+PostCmd = "rm_if_empty.sh"'
    echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
    echo "Executable = ${runlock}"
    echo "Universe   = vanilla"
    echo "Notification = never"
    # if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.                                                                             
    echo "request_memory = 1 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
    echo ""
    echo "Log          = log/$date/log_lock.txt"
    echo "Output       = log/$date/\$(Cluster).\$(Process).out"
    echo "Error       = log/$date/\$(Cluster).\$(Process).err"
    echo ""

} > $outsdflock

runtime="$PWD/run_timeseries.sh"
pytime="$Kozapy/batch_timeseries.py"
{
    echo "PWD = $Fp(SUBMIT_FILE)"
    echo "transfer_input_files = rm_if_empty.sh"
    echo '+PostCmd = "rm_if_empty.sh"'
    echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
    echo "Executable = ${runtime}"
    echo "Universe   = vanilla"
    echo "Notification = never"
    # if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.                                                                             
    echo "request_memory = 1 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
    echo ""
    echo "Log          = log/$date/log_timeseries.txt"
    echo "Output       = log/$date/\$(Cluster).\$(Process).out"
    echo "Error       = log/$date/\$(Cluster).\$(Process).err"
    echo ""
} > $outsdftime

runspectrum="$PWD/run_spectrum.sh"
pyspectrum="$Kozapy/batch_spectrum.py"
{
    echo "PWD = $Fp(SUBMIT_FILE)"
    echo "transfer_input_files = rm_if_empty.sh"
    echo '+PostCmd = "rm_if_empty.sh"'
    echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
    echo "Executable = ${runspectrum}"
    echo "Universe   = vanilla"
    echo "Notification = never"
    # if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.                                                                             
    echo "request_memory = 1 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
    echo ""
    echo "Log          = log/$date/log_spectrum.txt"
    echo "Output       = log/$date/\$(Cluster).\$(Process).out"
    echo "Error       = log/$date/\$(Cluster).\$(Process).err"
    echo ""
} > $outsdfspectrum

runspectrogram="$PWD/run_whitening_spectrogram.sh"
pyspectrogram="$Kozapy/batch_whitening_spectrogram.py"
{
    echo "PWD = $Fp(SUBMIT_FILE)"
    echo "transfer_input_files = rm_if_empty.sh"
    echo '+PostCmd = "rm_if_empty.sh"'
    echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
    echo "Executable = ${runspectrogram}"
    echo "Universe   = vanilla"
    echo "Notification = never"
    # if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.                                                                             
    echo "request_memory = 1 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
    echo ""
    echo "Log          = log/$date/log_spectrogram.txt"
    echo "Output       = log/$date/\$(Cluster).\$(Process).out"
    echo "Error       = log/$date/\$(Cluster).\$(Process).err"
    echo ""
} > $outsdfspectrogram

runcoherence="$PWD/run_coherencegram.sh"
pycoherence="$Kozapy/batch_coherencegram.py"
{
    echo "PWD = $Fp(SUBMIT_FILE)"
    echo "transfer_input_files = rm_if_empty.sh"
    echo '+PostCmd = "rm_if_empty.sh"'
    echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
    echo "Executable = ${runcoherence}"
    echo "Universe   = vanilla"
    echo "Notification = never"
    # if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.                                                                             
    echo "request_memory = 1 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
    echo ""
    echo "Log          = log/$date/log_coherencegram.txt"
    echo "Output       = log/$date/\$(Cluster).\$(Process).out"
    echo "Error       = log/$date/\$(Cluster).\$(Process).err"
    echo ""
} > $outsdfcoherence

runqtrans="$PWD/run_qtransform.sh"
pyqtrans="$Kozapy/batch_qtransform.py"
{
    echo "PWD = $Fp(SUBMIT_FILE)"
    echo "transfer_input_files = rm_if_empty.sh"
    echo '+PostCmd = "rm_if_empty.sh"'
    echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
    echo "Executable = ${runqtrans}"
    echo "Universe   = vanilla"
    echo "Notification = never"
    # if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.                                                                             
    echo "request_memory = 16 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
    echo ""
    echo "Log          = log/$date/log_qtransform.txt"
    echo "Output       = log/$date/\$(Cluster).\$(Process).out"
    echo "Error       = log/$date/\$(Cluster).\$(Process).err"
    echo ""
} > $outsdfqtrans

ok="Successfully finished !"

for log in ${list[@]}; do

    plottype=$(head -n 1 $log )
    argument=$(head -n 2 $log | tail -n 1)
    # empty channel
#    if [ "`echo $argument | grep TM_LOCK_ `" ]; then
#	continue
#    elif [ "`echo $argument | grep IM_LOCK_ `" ]; then
#	continue
#    elif [ "`echo $argument | grep MN_LOCK_ `" ]; then
#	continue
#    elif [ "`echo $argument | grep PEM-SEIS_MCE `" ]; then
#	continue
#    elif [ "`echo $argument | grep K1:IMC-SERVO_ | grep _MON_OUT_DQ `" ]; then
#	continue
#    fi

#    if "true"; then
#	:
#    if [ "`echo $argument | grep 124706 `" ]; then
#	continue

 
    if [ "$argument" = "" ]; then
	continue
#    elif [ "`echo $argument | grep K1:LSC-POP `" ]; then
#	echo 3
#	continue
    elif [ "`echo $argument | grep glitch_1244010447.5_K1:AOS-TMSX_IR_PD_OUT_DQ `" ]; then
	continue
    elif [ "`echo $argument | grep glitch_1244012928.0_K1:IMC-MCL_SERVO_OUT_DQ `" ]; then
	continue
    elif [ "`echo $argument | grep 1244018491.201172113  `" ]; then
	argument=`echo $argument | sed s/491.201172113/491.20117/g`

#    elif [ "`echo $argument | grep REFL_PDA1_DC_OUT_DQ `" ]; then
#	argument=`echo $argument | sed s/REFL_PDA1_DC_OUT_DQ/REFL_PDA1_DC_IN1_DQ/g`
#    elif [ "`echo $argument | grep _OUTPUT `" ]; then
#	if [ "`echo $plottype | grep qtransform `" ]; then
#	    continue
#	elif [ "`echo $plottype | grep coherence `" ]; then
#	    continue
#	fi
#    elif [ "`echo $argument | grep 1247040413.81  `" ]; then
#	argument=`echo $argument | sed s/1247040413.81/1247040414/g`
#	argument=`echo $argument | sed s/1247040419.81/1247040420/g`
    fi

    checkword=$(tail -n 1 $log)
    output=$(tail -n 2 $log | head -n 1)

    if [ "`echo $output | grep _124706 `" ]; then
	continue
    fi
    # set output sdf file.
#    if [ "`echo $argument | grep series `" ]; then
    if [ "$plottype" = "timeseries" ]; then
	tmpsdf=$outsdftime
#    elif [ "`echo $argument | grep '\-r' `" ]; then
    elif [ "$plottype" = "coherencegram" ]; then
	tmpsdf=$outsdfcoherence
    elif [ "$plottype" = "coherence" ]; then
	tmpsdf=$outsdfcoherence
#    elif [ "`echo $argument | grep stride `" ]; then
    elif [ "$plottype" = "spectrogram" ]; then
	tmpsdf=$outsdfspectrogram
    elif [ "$plottype" = "whitening_spectrogram" ]; then
	tmpsdf=$outsdfspectrogram
#    elif [ "`echo $argument | grep time `" ]; then
    elif [ "$plottype" = "spectrum" ]; then
	tmpsdf=$outsdfspectrum
#    elif [ "`echo $argument | grep '\-d' `" ]; then
    elif [ "$plottype" = "locksegments" ]; then
	tmpsdf=$outsdflock
    elif [ "$plottype" = "lock" ]; then
	tmpsdf=$outsdflock
#    elif [ "`echo $argument | grep qtrans `" ]; then
    elif [ "$plottype" = "qtransform" ]; then
	tmpsdf=$outsdfqtrans
    else
	echo "Warning !!! plot type is unknown." $plottype
    fi

    #echo $tmpsdf

    outls=`ls -s ${output}`
    badls="0 ${output}"


    if test "$outls" = "$badls" ;then
	echo $output " is broken !"
	#echo $log

	{
	    echo "# $log"
	    echo "Arguments = $argument "
            echo "Queue"
	    
	} >> $tmpsdf

    elif test "$ok" = "$checkword" ;then
	if [ -e ${output} ];then
	    :
	    echo $log " successfully finished."
	    rm -rf $log
	    tmplog=`echo $log | sed s/out/err/g`
	    rm -rf $tmplog
	else
	    :
	    echo $log " is not found !"
#	{
#	    echo "Arguments = $argument "
#	    echo "Output       = log/$date/out_\$(Cluster).\$(Process).txt"
#           echo "Error        = log/$date/err_\$(Cluster).\$(Process).txt"
#            echo "Log          = log/$date/log_\$(Cluster).\$(Process).txt"
#            echo "Queue"
#	} >> $tmpsdf

	fi
    else	
	echo $log " is not processed !"

	{
	    echo "# $log"
	    echo "Arguments = $argument "
            echo "Queue"
	} >> $tmpsdf

    fi


done 

condor_submit $outsdftime
condor_submit $outsdfspectrum
condor_submit $outsdfspectrogram
condor_submit $outsdfcoherence
condor_submit $outsdfqtrans
condor_submit $outsdflock
