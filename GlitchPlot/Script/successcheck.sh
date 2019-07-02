#!/bin/bash

date=20190608

#if "${kamioka}"; then
#    Kozapy="/users/DET/tools/GlitchPlot/Script/Kozapy/samples"
#else
    Kozapy="/home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples"
#fi

list=( `find log/20190608/out_259* -newermt "2019-06-29 08:45:00"` )

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
        echo "#!/bin/bash"
        echo ""
        echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
        echo "# This file is generated from `basename $0`."
        echo "# If you need to change, please edit `basename $0`."
        echo ""
        echo "echo lock"
        echo "echo \$@"
        echo "python $pylock \$@"

} > $runlock
chmod u+x $runlock
{
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
} > $outsdflock

runtime="$PWD/run_timeseries.sh"
pytime="$Kozapy/batch_timeseries.py"
{
        echo "#!/bin/bash"
        echo ""
        echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
        echo "# This file is generated from `basename $0`."
        echo "# If you need to change, please edit `basename $0`."
        echo ""
        echo "echo timeseries"
        echo "echo \$@"
        echo "python $pytime \$@"

} > $runtime
chmod u+x $runtime
{
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
} > $outsdftime

runspectrum="$PWD/run_spectrum.sh"
pyspectrum="$Kozapy/batch_spectrum.py"
{
        echo "#!/bin/bash"
        echo ""
        echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
        echo "# This file is generated from `basename $0`."
        echo "# If you need to change, please edit `basename $0`."
        echo ""
        echo "echo spectrum"
        echo "echo \$@"
        echo "python $pyspectrum \$@"

} > $runspectrum
chmod u+x $runspectrum
{
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
} > $outsdfspectrum

runspectrogram="$PWD/run_whitening_spectrogram.sh"
pyspectrogram="$Kozapy/batch_whitening_spectrogram.py"
{
        echo "#!/bin/bash"
        echo ""
        echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
        echo "# This file is generated from `basename $0`."
        echo "# If you need to change, please edit `basename $0`."
        echo ""
        echo "echo spectrogram"
        echo "echo \$@"
        echo "python $pyspectrogram \$@"

} > $runspectrogram
chmod u+x $runspectrogram
{
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
} > $outsdfspectrogram

runcoherence="$PWD/run_coherencegram.sh"
pycoherence="$Kozapy/batch_coherencegram.py"
{
        echo "#!/bin/bash"
        echo ""
        echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
        echo "# This file is generated from `basename $0`."
        echo "# If you need to change, please edit `basename $0`."
        echo ""
        echo "echo coherencegram"
        echo "echo \$@"
        echo "python $pycoherence \$@"

} > $runcoherence
chmod u+x $runcoherence
{
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
} > $outsdfcoherence

runqtrans="$PWD/run_qtransform.sh"
pyqtrans="$Kozapy/batch_qtransform.py"
{
        echo "#!/bin/bash"
        echo ""
        echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
        echo "# This file is generated from `basename $0`."
        echo "# If you need to change, please edit `basename $0`."
        echo ""
        echo "echo qtransform"
        echo "echo \$@"
        echo "python $pyqtrans \$@"

} > $runqtrans
chmod u+x $runqtrans
{
    echo "Executable = ${runqtrans}"
    echo "Universe   = vanilla"
    echo "Notification = never"
    # if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.                                                                             
    echo "request_memory = 1 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
    echo ""
} > $outsdfqtrans

ok="Successfully finished !"

for log in ${list[@]}; do

    argument=$(head -n 1 $log)
    # empty channel
    if [ "`echo $argument | grep TM_LOCK_ `" ]; then
	continue
    elif [ "`echo $argument | grep IM_LOCK_ `" ]; then
	continue
    elif [ "`echo $argument | grep MN_LOCK_ `" ]; then
	continue
    elif [ "`echo $argument | grep PEM-SEIS_MCE `" ]; then
	continue
    elif [ "`echo $argument | grep K1:IMC-SERVO_ | grep _MON_OUT_DQ `" ]; then
	continue
    elif [ "`echo $argument | grep PEM-MAG_BS_BOOTH_BS_X `" ]; then
	echo "wrong channel."
	argument=`echo $argument | sed -e 's/PEM-MAG_BS_BOOTH_BS_X/PEM-MAG_BS_BOOTH_BS_X_OUT_DQ/g'`
    elif [ "`echo $argument | grep PEM-MAG_BS_BOOTH_BS_Y `" ]; then
	echo "wrong channel."
	argument=`echo $argument | sed -e 's/PEM-MAG_BS_BOOTH_BS_Y/PEM-MAG_BS_BOOTH_BS_Y_OUT_DQ/g'`
    elif [ "`echo $argument | grep PEM-MAG_BS_BOOTH_BS_Z `" ]; then
	echo "wrong channel."
	argument=`echo $argument | sed -e 's/PEM-MAG_BS_BOOTH_BS_Z/PEM-MAG_BS_BOOTH_BS_Z_OUT_DQ/g'`
    elif [ "`echo $argument | grep NORM_OUTPUT `" ]; then
	# qtransform may fail.
	continue
    fi

    checkword=$(tail -n 1 $log)
    output=$(tail -n 2 $log | head -n 1)

    # set output sdf file.
    if [ "`echo $argument | grep series `" ]; then
	tmpsdf=$outsdftime
    elif [ "`echo $argument | grep '\-r' `" ]; then
	tmpsdf=$outsdfcoherence
    elif [ "`echo $argument | grep stride `" ]; then
	tmpsdf=$outsdfspectrogram
    elif [ "`echo $argument | grep time `" ]; then
	tmpsdf=$outsdfspectrum
    elif [ "`echo $argument | grep '\-d' `" ]; then
	tmpsdf=$outsdflock
#    elif [ "`echo $argument | grep qtrans `" ]; then
    else
	tmpsdf=$outsdfqtrans
    fi

    echo $tmpsdf

    outls=`ls -s ${output}`
    badls="0 ${output}"


    if test "$outls" = "$badls" ;then
	echo $output " is broken !"
	echo $log

	{
	    echo "# $log"
	    echo "Arguments = $argument "
	    echo "Output       = log/$date/out_\$(Cluster).\$(Process).txt"
            echo "Error        = log/$date/err_\$(Cluster).\$(Process).txt"
            echo "Log          = log/$date/log_\$(Cluster).\$(Process).txt"
            echo "Queue"
	    
	} >> $tmpsdf

    elif test "$ok" = "$checkword" ;then
	if [ -e ${output} ];then
	    echo $log " successfully finished."
	else
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
	    echo "Output       = log/$date/out_\$(Cluster).\$(Process).txt"
            echo "Error        = log/$date/err_\$(Cluster).\$(Process).txt"
            echo "Log          = log/$date/log_\$(Cluster).\$(Process).txt"
            echo "Queue"
	} >> $tmpsdf

    fi
done 
