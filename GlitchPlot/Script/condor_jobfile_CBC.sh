#!/bin/bash

################################################################
# This file is for submitting trigger related plot job into condor.
#
# Recommendation: 
# 
# In python script, package Kozapy/samples/mylib/ is reuired.
# Please make symbolic link in your working directory like this. 
# $ ln -s /path/to/Kozapy/samples/mylib/ mylib
#
################################################################

# Define variables.

nametime="timeseries"
namespectrum="spectrum"
namespectrogram="whitening_spectrogram"
namecoherencegram="coherencegram"
nameqtransform="qtransform"
namelock="locksegments"

eventtype="CBC"
channel="K1:CAL-CS_PROC_C00_STRAIN_DBL_DQ"

#cat $1 | while read gpstime channel min_duration max_duration bandwidth maxSNR frequency_snr max_amp frequency_amp eventtype triggertype eventnumber
cat $1 | while read gpstime rho reduced_chi_square detection_statistics
do

    # $index will be added to the output file name to distinguish from others. 
    index=$eventtype"_"$gpstime"_"$channel

    # channel list file can be generated by hand or by chlist.sh.
    # chlist.sh will not rewrite existing file. 

    channels=$channel".dat"
    ./chlist_plotter.sh $channels $channel

    # For timeseries, gps time start from 2s before glitch and end at 2s after glitch.

    # For spectrum, spectogram, and coherencegram,
    # fftlength is defined based on bandwidth of the trigger event.
    # For spectrum, fft length = 1/bandwidth, rounded to integer.
    fft30=1

    # determine time scale to use. around 30s, use a nice round number.
    # divide is number of bins. 
    # span is total data length.
    span30=30

    # for spectrogram etc.
    # fft length = larger one of [min_duration] or [max_duration/10]
    # stride = multiple of fft length, 

    fft=0.125

    stride=0.125
    span=5

    gpsstart=`echo "scale=5; $gpstime - $span " | bc `
    gpsend=`echo "scale=5; $gpstime + $span " | bc `

    qgpsstart=`echo "scale=5; $gpstime - $span " | bc `
    qgpsend=`echo "scale=5; $gpstime + $span " | bc `

    # after trigger
    gpsstart1=`echo "scale=5; $gpstime + 2. " | bc | awk '{printf("%d\n",$1 + 1)}'`
    gpsend1=`echo "scale=5; $gpstime + 2. + $span30 " | bc | awk '{printf("%d\n",$1 + 1)}'`
    #before trigger
    gpsstart2=`echo "scale=5; $gpstime - 30. - $span30 " | bc | awk '{printf("%d\n",$1 - 1)}'`
    gpsend2=`echo "scale=5; $gpstime - 30. " | bc | awk '{printf("%d\n",$1 - 1)}'`


    gpsstart3=`echo "scale=5; $gpstime - 1. " | bc `
    gpsend3=$gpstime
    
    gpsstarts30=($gpsstart3 $gpsstart1 $gpsstart2 )
    gpsends30=($gpsend3 $gpsend1 $gpsend2 )
    titles=("Trigger" "After" "Before")

    # Data type for time series. Default is to use minutes trend. second trend or full data can be used with following flags. Please set one of them true and set the others false. Or it will give warning message and exit. 
    #data="minute"
    #data="second"
    data="full"

    if [ `hostname` == "k1sum1" ]; then
	kamioka=true
    else
	kamioka=false
    fi
    #kamioka=true
    #kamioka=false

    if [ $USER == "detchar" ]; then
        detchar=true
    else
        detchar=false
    fi
    # For locked segments bar plot.
    lock=true
    #lock=false

    # IMC lock
    #lchannel="K1:GRD-IO_STATE_N.mean"  #guardian channel
    #lchannel="K1:GRD-IO_STATE_N"  #guardian channel
    #lnumber=99  #number of the required state
    #llabel='IMC_LSC'  #y-axis label for the bar plot.

    # X-arm lock
#    lchannel="K1:GRD-LSC_LOCK_STATE_N"  #guardian channel
#    lnumber=10  #number of the required state
#    llabel='X-arm'  #y-axis label for the bar plot.

    # FPMI lock
    lchannel="K1:GRD-LSC_LOCK_STATE_N"  #guardian channel
    lnumber=60  #number of the required state
    llabel='FPMI'  #y-axis label for the bar plot.

    # ALSDARM lock
    #lchannel="K1:GRD-LSC_LOCK_STATE_N"  #guardian channel
    #lnumber=40  #number of the required state
    #llabel='ALSDARM'  #y-axis label for the bar plot.

    # ALSDARM+PR lock
    #lchannel="K1:GRD-LSC_LOCK_STATE_N"  #guardian channel
    #lnumber=171  #number of the required state
    #llabel='PRMI+ALSDARM'  #y-axis label for the bar plot.


    #  lock
#    lchannel="K1:GRD-LSC_LOCK_STATE_N"  #guardian channel
#    lnumber=157  #number of the required state
#    llabel='LSC'  #y-axis label for the bar plot.

    
    # Set the output directory.
#    condir="/users/.ckozakai/KashiwaAnalysis/analysis/code/gwpy/trigger/plotter"

    if "${kamioka}"; then
	condir="/users/DET/Result/GlitchPlot"
    elif "${detchar}"; then
        condir="/home/detchar/public_html/GlitchPlot"
    else
	condir="/home/chihiro.kozakai/public_html/KAGRA/GlitchPlot"
    fi

    if [ "$condir" = "" ]; then
	condir=$PWD
    fi

    if "${kamioka}"; then
	[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime
	date=`${cmd_gps} ${gpstime}| head -1`
	set ${date}
	date=`echo ${2}| sed -e 's/-//g'`
    else
	date=`tconvert -l -f %Y%m%d ${gpstime}`
    fi

    outdir="$condir/$date/${index}/"
  

    # Confirm the existance of output directory.

    if [ ! -e $outdir ]; then
	mkdir -p $outdir
    fi

    {
	#echo $gpstime $channel $min_duration $max_duration $bandwidth $maxSNR $frequency_snr $max_amp $frequency_amp  $eventtype $triggertype $eventnumber
	echo $gpstime $channel 0.125 0.125 8 $detection_statistics 100 $detection_statistics 100  CBC kagalin 0
    } > $outdir/parameter.txt

    logdir="$PWD/log/$date/"
    if [ ! -e $logdir ]; then
	mkdir -p $logdir
    fi

    # make main script.

    # for time series.

    if "${kamioka}"; then
	Kozapy="/users/DET/tools/GlitchPlot/Script/Kozapy/samples"
    else
	Kozapy="/home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples"
    fi

    runtime="$PWD/run_${nametime}.sh"
    pytime="$Kozapy/batch_${nametime}.py"
    #py="~/batch_timesries.py"  # For the case you use non-conventional python script name.

#    {
#	echo "#!/bin/bash"
#	echo ""
#	echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
#	echo "# This file is generated from `basename $0`."
#	echo "# If you need to change, please edit `basename $0`."
#	echo ""
#	echo "echo timeseries"
#	echo "echo \$@"
#	echo "python $pytime \$@"
#	
#   } > $runtime

#    chmod u+x $runtime

    # Write a file for condor submission.
    
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
	echo "Log          = log/$date/log_${nametime}.txt"
	echo "Output       = log/$date/\$(Cluster).\$(Process).out"
	echo "Error       = log/$date/\$(Cluster).\$(Process).err"
	echo ""
    } > job_${nametime}.sdf

    # for spectrum series.
    
    runspectrum="$PWD/run_${namespectrum}.sh"
    pyspectrum="$Kozapy/batch_${namespectrum}.py"
    #py="~/batch_spectrumsries.py"  # For the case you use non-conventional python script name.

#    {
#	echo "#!/bin/bash"
#	echo ""
#	echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
#	echo "# This file is generated from `basename $0`."
#	echo "# If you need to change, please edit `basename $0`."
#	echo ""
#	echo "echo spectrum"
#	echo "echo \$@"
#	echo "python $pyspectrum \$@"
#	
#    } > $runspectrum

#    chmod u+x $runspectrum

    # Write a file for condor submission.
    
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
	echo "Log          = log/$date/log_${namespectrum}.txt"
	echo "Output       = log/$date/\$(Cluster).\$(Process).out"
	echo "Error       = log/$date/\$(Cluster).\$(Process).err"
	echo ""
    } > job_${namespectrum}.sdf

    # for spectrogram series.
    
    runspectrogram="$PWD/run_${namespectrogram}.sh"
    pyspectrogram="$Kozapy/batch_${namespectrogram}.py"
    #py="~/batch_spectrogramsries.py"  # For the case you use non-conventional python script name.

#    {
#	echo "#!/bin/bash"
#	echo ""
#	echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
#	echo "# This file is generated from `basename $0`."
#	echo "# If you need to change, please edit `basename $0`."
#	echo ""
#	echo "echo whitening_spectrogram"
#	echo "echo \$@"
#	echo "python $pyspectrogram \$@"
#	
#    } > $runspectrogram

#    chmod u+x $runspectrogram

    # Write a file for condor submission.
    
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
	echo "Log          = log/$date/log_${namespectrogram}.txt"
	echo "Output       = log/$date/\$(Cluster).\$(Process).out"
	echo "Error       = log/$date/\$(Cluster).\$(Process).err"
	echo ""
    } > job_${namespectrogram}.sdf

    # for coherencegram series.
    
    runcoherencegram="$PWD/run_${namecoherencegram}.sh"
    pycoherencegram="$Kozapy/batch_${namecoherencegram}.py"
    #py="~/batch_coherencegramsries.py"  # For the case you use non-conventional python script name.

#    {
#	echo "#!/bin/bash"
#	echo ""
#	echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
#	echo "# This file is generated from `basename $0`."
#	echo "# If you need to change, please edit `basename $0`."
#	echo ""
#	echo "echo coherencegram"
#	echo "echo \$@"
#	echo "python $pycoherencegram \$@"
#	
#    } > $runcoherencegram

#    chmod u+x $runcoherencegram

    # Write a file for condor submission.
    
    {
	echo "PWD = $Fp(SUBMIT_FILE)"
	echo "transfer_input_files = rm_if_empty.sh"
	echo '+PostCmd = "rm_if_empty.sh"'
	echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
	echo "Executable = ${runcoherencegram}"
	echo "Universe   = vanilla"
	echo "Notification = never"
	# if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.
	echo "request_memory = 1 GB"
	echo "Getenv  = True            # the environment variables will be copied."
	echo ""
	echo "should_transfer_files = YES"
	echo "when_to_transfer_output = ON_EXIT"
	echo ""
	echo "Log          = log/$date/log_${namecoherencegram}.txt"
	echo "Output       = log/$date/\$(Cluster).\$(Process).out"
	echo "Error       = log/$date/\$(Cluster).\$(Process).err"
	echo ""
    } > job_${namecoherencegram}.sdf

    # for qtransform.
    
    runqtransform="$PWD/run_${nameqtransform}.sh"
    pyqtransform="$Kozapy/batch_${nameqtransform}.py"
    #py="~/batch_qtransformsries.py"  # For the case you use non-conventional python script name.

#    {
#	echo "#!/bin/bash"
#	echo ""
#	echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
#	echo "# This file is generated from `basename $0`."
#	echo "# If you need to change, please edit `basename $0`."
#	echo ""
#	echo "echo qtransform"
#	echo "echo \$@"
#	echo "python $pyqtransform \$@"
	
#    } > $runqtransform

#    chmod u+x $runqtransform

    # Write a file for condor submission.
    
    {
	echo "PWD = $Fp(SUBMIT_FILE)"
	echo "transfer_input_files = rm_if_empty.sh"
	echo '+PostCmd = "rm_if_empty.sh"'
	echo '+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"'
	echo "Executable = ${runqtransform}"
	echo "Universe   = vanilla"
	echo "Notification = never"
	# if needed, use following line to set the necessary amount of the memory for a job. In Kashiwa, each node has total memory 256 GB, 2 CPU, 28 cores.
	echo "request_memory = 8 GB"
	echo "Getenv  = True            # the environment variables will be copied."
	echo ""
	echo "should_transfer_files = YES"
	echo "when_to_transfer_output = ON_EXIT"
	echo ""
	echo "Log          = log/$date/log_${nameqtransform}.txt"
	echo "Output       = log/$date/\$(Cluster).\$(Process).out"
	echo "Error       = log/$date/\$(Cluster).\$(Process).err"
	echo ""
    } > job_${nameqtransform}.sdf

    # for lock segmnet.
    
    runlock="$PWD/run_${namelock}.sh"
    pylock="$Kozapy/batch_${namelock}.py"
    #py="~/batch_qtransformsries.py"  # For the case you use non-conventional python script name.

#    {
#	echo "#!/bin/bash"
#	echo ""
#	echo "# PLEASE NEVER CHANGE THIS FILE BY HAND."
#	echo "# This file is generated from `basename $0`."
#	echo "# If you need to change, please edit `basename $0`."
#	echo ""
#	echo "echo locksegments"
#	echo "echo \$@"
#	echo "python $pylock \$@"
#	
#    } > $runlock

#    chmod u+x $runlock

    # Write a file for condor submission.
    
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
	echo "Log          = log/$date/log_${namelock}.txt"
	echo "Output       = log/$date/\$(Cluster).\$(Process).out"
	echo "Error       = log/$date/\$(Cluster).\$(Process).err"
	echo ""
    } > job_${namelock}.sdf

    {
	# Please try
	#  $ python batch_locksegments.py -h
	# for option detail.
	
	echo "Arguments = -s $gpsstart -e $gpsend -o ${outdir} -i $channel -t $gpstime -d $max_duration "
	echo "Queue"
    } >> job_${namelock}.sdf
	
    echo job_${namelock}.sdf
    condor_submit job_${namelock}.sdf

    # Loop over each plot. 
    option=""
    if "${kamioka}" ; then
	option+=" -k"
    fi

    optionspectrum=$option
    optioncoherencegram=$option
    
    if "${lock}" ; then
	option+=" -l ${lchannel} -n ${lnumber} --llabel ${llabel}"
    else
	echo "lock is false."
    fi

    optioncoherencegram=$option
    optionspectrogram=$option
    optionqtransform=$option
    
    if [ $data = "minute" ] ; then
	option+=" -d minute"
    elif [ $data = "second" ] ; then
	option+=" -d second"
    elif [ $data = "full" ] ; then
	option+=" -d full"
    fi

    optiontime=$option

    cat $channels | while read chlist
    do
	# timeseries job
	{
	    # Please try
	    #  $ python batch_timeseries.py -h
	    # for option detail.
	    
	    echo "Arguments = -c ${chlist[@]} -s $gpsstart -e $gpsend -o ${outdir} -i $channel ${optiontime} -t ${chlist[0]}_Timeseries --nolegend --dpi 50 -w -b"
	    echo "Queue"
	} >> job_${nametime}.sdf

	# If low sampling channel, only time series plot will be made. 
	if [ "`echo ${chlist[@]} | grep _OUTPUT `" ]; then
	    continue
	fi

	# coherencegram job
	{
	    # Please try
	    #  $ python batch_coherencegram.py -h
	    # for option detail.
	    
	    echo "Arguments = -r $channel -c ${chlist[@]} -s ${gpsstart} -e ${gpsend} -o ${outdir} -i $channel -f ${fft} --stride ${stride} ${optioncoherencegram} --dpi 50"
	    echo "Queue"

#	    echo "Arguments = -r $channel -c ${chlist[@]} -s ${gpsstart} -e ${gpsend} -o ${outdir} -i $channeldur -f ${duration} --stride ${durstride} ${optioncoherencegram}"
#	    echo "Output       = log/$date/out_\$(Cluster).\$(Process).txt"
#	    echo "Error        = log/$date/err_\$(Cluster).\$(Process).txt"
#	    echo "Log          = log/$date/log_\$(Cluster).\$(Process).txt"
#	    echo "Queue"
	} >> job_${namecoherencegram}.sdf


	# spectrum job

	if [ "$eventtype" = "lockloss" ]; then
	    :
	else
	    {
		# Please try
		#  $ python batch_spectrum.py -h
		# for option detail.
		
		echo "Arguments = -c ${chlist[@]} -s ${gpsstarts30[@]} -e ${gpsends30[@]} -o ${outdir} -i $channel -t time -f ${fft30} --title ${titles[@]} ${optionspectrum} --dpi 50"
		echo "Queue"
	    } >> job_${namespectrum}.sdf
	fi

	# spectrogram job
	{
	    # Please try
	    #  $ python batch_ehitening_spectrogram.py -h
	    # for option detail.
	    
	    echo "Arguments = -c ${chlist[@]} -s ${gpsstart} -e ${gpsend} -o ${outdir} -i $channel -f ${fft} --stride ${stride} ${optionspectrogram} --dpi 50"
	    echo "Queue"

	    echo "Arguments = -c ${chlist[@]} -s ${gpsstart} -e ${gpsend} -o ${outdir} -i $channel -f ${fft} --stride ${stride} ${optionspectrogram} -w --dpi 50"
	    echo "Queue"


	} >> job_${namespectrogram}.sdf


	# qtransform job
	{
	    # Please try
	    #  $ python batch_coherencegram.py -h
	    # for option detail.
	    
	    echo "Arguments = -c ${chlist[@]} -s ${qgpsstart} -e ${qgpsend} -o ${outdir} -i $channel ${optionqtransform} -f ${fmin} --dpi 50"
	    echo "Queue"

	} >> job_${nameqtransform}.sdf

#	done
	# end of gps time list

    done
    # end of channel list
    # Submit job into condor.
    echo job_${nametime}.sdf
    condor_submit job_${nametime}.sdf
    echo job_${namespectrum}.sdf
    condor_submit job_${namespectrum}.sdf
    echo job_${namespectrogram}.sdf
    condor_submit job_${namespectrogram}.sdf
    echo job_${namecoherencegram}.sdf
    condor_submit job_${namecoherencegram}.sdf
    echo job_${nameqtransform}.sdf
    condor_submit job_${nameqtransform}.sdf

done
# end of parameter.txt
