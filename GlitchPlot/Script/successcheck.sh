#!/bin/bash

date=20190713

#if "${kamioka}"; then
#    Kozapy="/users/DET/tools/GlitchPlot/Script/Kozapy/samples"
#else
Kozapy="/home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples"
#fi

list=( `find log/20190713/out_173227* -newermt "2019-07-17 16:49:00"` )
#list=( `find log/20190608/out_45660* -newermt "2019-06-29 08:45:00"` )


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
        echo "echo whitening_spectrogram"
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
    echo "request_memory = 8 GB"
    echo "Getenv  = True            # the environment variables will be copied."
    echo ""
    echo "should_transfer_files = YES"
    echo "when_to_transfer_output = ON_EXIT"
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
    if [ "`echo $argument | grep 124706 `" ]; then
	continue
    elif [ "`echo $argument | grep SUM_OUT_DQ `" ]; then
	echo $argument | sed s/SUM_OUT_DQ/SUM_OUTPUT/g
    elif [ "`echo $argument | grep LEN_PIT_OUT_DQ `" ]; then
	echo $argument | sed s/LEN_PIT_OUT_DQ/LEN_PIT_OUTPUT/g
    elif [ "`echo $argument | grep 1247040413.81  `" ]; then
	echo $argument | sed s/1247040413.81/1247040414/g
	echo $argument | sed s/1247040419.81/1247040420/g
    elif [ "`echo $argument | grep 1247043589.12  `" ]; then
	echo $argument | sed s/1247043589.12/1247043589.1/g
	echo $argument | sed s/1247043648.12/1247043648.1/g
    elif [ "`echo $argument | grep 1247029018.81  `" ]; then
	echo $argument | sed s/1247029018.81/1247029018.8/g
	echo $argument | sed s/1247029024.81/1247029024.8/g
    elif [ "`echo $argument | grep 1247039003.94  `" ]; then
	echo $argument | sed s/1247039003.94/1247039004/g
	echo $argument | sed s/1247039009.94/1247039010/g
    elif [ "`echo $argument | grep 1247037370.88  `" ]; then
	echo $argument | sed s/1247037370.88/1247037370.9/g
	echo $argument | sed s/1247037376.88/1247037376.9/g
    elif [ "`echo $argument | grep 1247035837.53  `" ]; then
	echo $argument | sed s/837.53/837.5/g
	echo $argument | sed s/843.53/843.5/g

    elif [ "`echo $argument | grep 1247035707.19  `" ]; then
	echo $argument | sed s/707.19/707.2/g
	echo $argument | sed s/713.19/713.2/g

    elif [ "`echo $argument | grep 1247043645.34  `" ]; then
	echo $argument | sed s/645.34/645.3/g
	echo $argument | sed s/651.34/651.3/g

    elif [ "`echo $argument | grep 1247041989.81  `" ]; then
	echo $argument | sed s/989.81/989.8/g
	echo $argument | sed s/995.81/995.8/g

    elif [ "`echo $argument | grep 1247028657.91  `" ]; then
	echo $argument | sed s/657.91/657.9/g
	echo $argument | sed s/663.91/663.9/g

    elif [ "`echo $argument | grep 1247039480.38  `" ]; then
	echo $argument | sed s/480.38/480.4/g
	echo $argument | sed s/486.38/486.4/g

    elif [ "`echo $argument | grep 1247037728.81  `" ]; then
	echo $argument | sed s/728.81/728.8/g
	echo $argument | sed s/734.81/734.8/g

    elif [ "`echo $argument | grep 1247024289.25  `" ]; then
	echo $argument | sed s/289.25/289.3/g
	echo $argument | sed s/295.25/295.3/g

    elif [ "`echo $argument | grep 1247038793.69  `" ]; then
	echo $argument | sed s/793.69/793.7/g
	echo $argument | sed s/799.69/799.7/g

    elif [ "`echo $argument | grep 1247033220.44  `" ]; then
	echo $argument | sed s/220.44/220.4/g
	echo $argument | sed s/226.44/226.4/g
    elif [ "`echo $argument | grep 1247037644.99  `" ]; then
	echo $argument | sed s/644.99/645/g
	echo $argument | sed s/650.99/651/g
    elif [ "`echo $argument | grep 1247029587.13  `" ]; then
	echo $argument | sed s/587.13/587.1/g
	echo $argument | sed s/593.13/593.1/g
    elif [ "`echo $argument | grep 1247031212.56  `" ]; then
	echo $argument | sed s/212.56/212.6/g
	echo $argument | sed s/218.56/218.6/g
    elif [ "`echo $argument | grep 1247037741.78  `" ]; then
	echo $argument | sed s/741.78/741.8/g
	echo $argument | sed s/747.78/747.8/g
    elif [ "`echo $argument | grep 1247035707.19  `" ]; then
	echo $argument | sed s/707.19/707.2/g
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
#    elif [ "`echo $argument | grep qtrans `" ]; then
    elif [ "$plottype" = "qtransform" ]; then
	tmpsdf=$outsdfqtrans
    else
	echo "Warning !!! plot type is unknown." $plottype
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

condor_submit $outsdftime
condor_submit $outsdfspectrum
condor_submit $outsdfspectrogram
condor_submit $outsdfcoherence
condor_submit $outsdfqtrans
condor_submit $outsdflock
