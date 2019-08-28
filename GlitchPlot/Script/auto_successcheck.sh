#!/bin/bash

#if "${kamioka}"; then
#    Kozapy="/users/DET/tools/GlitchPlot/Script/Kozapy/samples"
#else
Kozapy="/home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples"
#fi

INTERVAL=15

#let mm=`date +"%M"`/${INTERVAL}*${INTERVAL}                                                 
let mm=`date +"%M" | sed -e "s/^0//"`/${INTERVAL}*${INTERVAL}


jst_end="`date +"%Y-%m-%d %H:${mm}:00"`"

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

#GPS_END=`${cmd_gps} ${jst_end}| head -3 | tail -1 | awk '{printf("%d\n", $2)}'`             
GPS_END=`tconvert -l $jst_end`

let GPS_START=${GPS_END}-${INTERVAL}*60

#jst_start=`${cmd_gps} ${GPS_START}| head -1`                                                
#jst_start=${jst_start#*:}                                                                   
jst_start=`tconvert -l -f "%Y-%m-%d %H:%M:%S" $GPS_START`

let tmp=${GPS_END:0:5}-1
#echo $tmp                                                                                   

list=()

today=`date +%Y%m%d`
yesterday=`date --date '1 day ago' +%Y%m%d`
date=$today
list+=( `find /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/log/$today/* -newermt "$jst_start" -and ! -newermt "$jst_end"` `find /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/log/$yesterday/* -newermt "$jst_start" -and ! -newermt "$jst_end"`  )

#list=( `find log/20190608/100*.out  ` )
#list=( `find log/20190713/10220*.out  ` )
#list=( `find log/20190608/out_45660* -newermt "2019-06-29 08:45:00"` )


#outsdf=retry_$(basename $insdf)
outsdftime=autoretry_timeseries.sdf
outsdfspectrum=autoretry_spectrum.sdf
outsdfspectrogram=autoretry_spectrogram.sdf
outsdfcoherence=autoretry_coherencegram.sdf
outsdfqtrans=autoretry_qtransform.sdf
outsdflock=autoretry_lock.sdf

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
    elif [ "`echo $argument | grep K1:LSC-POP `" ]; then
	continue
    elif [ "`echo $argument | grep glitch_1244010447.5_K1:AOS-TMSX_IR_PD_OUT_DQ `" ]; then
	continue

<<COMMENTOUT
 

    elif [ "`echo $argument | grep REFL_PDA1_DC_OUT_DQ `" ]; then
	argument=`echo $argument | sed s/REFL_PDA1_DC_OUT_DQ/REFL_PDA1_DC_IN1_DQ/g`
    elif [ "`echo $argument | grep SUM_OUT_DQ `" ]; then
	argument=`echo $argument | sed s/SUM_OUT_DQ/SUM_OUTPUT/g`
    elif [ "`echo $argument | grep _OUTPUT `" ]; then
	if [ "`echo $plottype | grep qtransform `" ]; then
	    continue
	elif [ "`echo $plottype | grep coherence `" ]; then
	    continue
	fi
    elif [ "`echo $argument | grep DC_OUT_DQ `" ]; then
	if [ "`echo $plottype | grep qtransform `" ]; then
	    continue
	elif [ "`echo $plottype | grep coherence `" ]; then
	    continue
	fi
    elif [ "`echo $argument | grep LEN_PIT_OUT_DQ `" ]; then
	argument=`echo $argument | sed s/LEN_PIT_OUT_DQ/LEN_PIT_OUTPUT/g`
    elif [ "`echo $argument | grep 1247040413.81  `" ]; then
	argument=`echo $argument | sed s/1247040413.81/1247040414/g`
	argument=`echo $argument | sed s/1247040419.81/1247040420/g`
    elif [ "`echo $argument | grep 1247043589.12  `" ]; then
	argument=`echo $argument | sed s/1247043589.12/1247043589.1/g`
	argument=`echo $argument | sed s/1247043648.12/1247043648.1/g`
    elif [ "`echo $argument | grep 1247029018.81  `" ]; then
	argument=`echo $argument | sed s/1247029018.81/1247029018.8/g`
	argument=`echo $argument | sed s/1247029024.81/1247029024.8/g`
    elif [ "`echo $argument | grep 1247039003.94  `" ]; then
	argument=`echo $argument | sed s/1247039003.94/1247039004/g`
	argument=`echo $argument | sed s/1247039009.94/1247039010/g`
    elif [ "`echo $argument | grep 1247037370.88  `" ]; then
	argument=`echo $argument | sed s/1247037370.88/1247037371/g`
	argument=`echo $argument | sed s/1247037376.88/1247037377/g`
    elif [ "`echo $argument | grep 1247037370.9  `" ]; then
	argument=`echo $argument | sed s/1247037370.9/1247037371/g`
	argument=`echo $argument | sed s/1247037376.9/1247037371/g`
    elif [ "`echo $argument | grep 1247035837.53  `" ]; then
	argument=`echo $argument | sed s/837.53/837.5/g`
	argument=`echo $argument | sed s/843.53/843.5/g`

    elif [ "`echo $argument | grep 1247035707.19  `" ]; then
	argument=`echo $argument | sed s/707.19/707/g`
	argument=`echo $argument | sed s/713.19/713/g`
    elif [ "`echo $argument | grep 1247035707.2  `" ]; then
	argument=`echo $argument | sed s/707.2/707/g`
	argument=`echo $argument | sed s/713.2/713/g`

    elif [ "`echo $argument | grep 1247043645.34  `" ]; then
	argument=`echo $argument | sed s/645.34/645/g`
	argument=`echo $argument | sed s/651.34/651/g`
    elif [ "`echo $argument | grep 1247043645.3  `" ]; then
	argument=`echo $argument | sed s/645.3/645/g`
	argument=`echo $argument | sed s/651.3/651/g`

    elif [ "`echo $argument | grep 1247041989.81  `" ]; then
	argument=`echo $argument | sed s/989.81/989.8/g`
	argument=`echo $argument | sed s/995.81/995.8/g`

    elif [ "`echo $argument | grep 1247028657.91  `" ]; then
	argument=`echo $argument | sed s/657.91/657.9/g`
	argument=`echo $argument | sed s/663.91/663.9/g`

    elif [ "`echo $argument | grep 1247039480.38  `" ]; then
	argument=`echo $argument | sed s/480.38/480.4/g`
	argument=`echo $argument | sed s/486.38/486.4/g`

    elif [ "`echo $argument | grep 1247037728.81  `" ]; then
	argument=`echo $argument | sed s/728.81/728.8/g`
	argument=`echo $argument | sed s/734.81/734.8/g`

    elif [ "`echo $argument | grep 1247024289.25  `" ]; then
	argument=`echo $argument | sed s/289.25/289.3/g`
	argument=`echo $argument | sed s/295.25/295.3/g`

    elif [ "`echo $argument | grep 1247038793.69  `" ]; then
	argument=`echo $argument | sed s/793.69/793.7/g`
	argument=`echo $argument | sed s/799.69/799.7/g`

    elif [ "`echo $argument | grep 1247033220.44  `" ]; then
	argument=`echo $argument | sed s/220.44/220.4/g`
	argument=`echo $argument | sed s/226.44/226.4/g`
    elif [ "`echo $argument | grep 1247037644.99  `" ]; then
	argument=`echo $argument | sed s/644.99/645/g`
	argument=`echo $argument | sed s/650.99/651/g`
    elif [ "`echo $argument | grep 1247029587.13  `" ]; then
	argument=`echo $argument | sed s/587.13/587.1/g`
	argument=`echo $argument | sed s/593.13/593.1/g`
    elif [ "`echo $argument | grep 1247031212.56  `" ]; then
	argument=`echo $argument | sed s/212.56/212.6/g`
	argument=`echo $argument | sed s/218.56/218.6/g`
    elif [ "`echo $argument | grep 1247037741.78  `" ]; then
	argument=`echo $argument | sed s/741.78/741.8/g`
	argument=`echo $argument | sed s/747.78/747.8/g`
    elif [ "`echo $argument | grep 1247043486.12  `" ]; then
	argument=`echo $argument | sed s/43486.12/43486.1/g`
	argument=`echo $argument | sed s/43520.12/43520.1/g`
    elif [ "`echo $argument | grep 1247043486.1  `" ]; then
	argument=`echo $argument | sed s/43486.1/43486.1/g`
	argument=`echo $argument | sed s/43520.12/43520.1/g`
    elif [ "`echo $argument | grep 1247039038.12  `" ]; then
	argument=`echo $argument | sed s/038.12/038/g`
	argument=`echo $argument | sed s/044.12/044/g`
    elif [ "`echo $argument | grep 1247039038.1  `" ]; then
	argument=`echo $argument | sed s/038.1/038/g`
	argument=`echo $argument | sed s/044.1/044/g`
    elif [ "`echo $argument | grep 1247043493.12  `" ]; then
	argument=`echo $argument | sed s/493.12/493/g`
	argument=`echo $argument | sed s/552.12/552/g`
    elif [ "`echo $argument | grep 1247043493.1  `" ]; then
	argument=`echo $argument | sed s/493.1/493/g`
	argument=`echo $argument | sed s/552.12/552/g`
    elif [ "`echo $argument | grep 1247043479.94  `" ]; then
	argument=`echo $argument | sed s/479.94/480/g`
	argument=`echo $argument | sed s/547.94/548/g`
    elif [ "`echo $argument | grep 1247043479.9  `" ]; then
	argument=`echo $argument | sed s/479.9/480/g`
	argument=`echo $argument | sed s/547.9/548/g`
    elif [ "`echo $argument | grep 1247043500.88  `" ]; then
	argument=`echo $argument | sed s/500.88/501/g`
	argument=`echo $argument | sed s/534.88/535/g`
    elif [ "`echo $argument | grep 1247043500.9  `" ]; then
	argument=`echo $argument | sed s/500.9/501/g`
	argument=`echo $argument | sed s/534.9/535/g`
    elif [ "`echo $argument | grep 1247043486.31  `" ]; then
	argument=`echo $argument | sed s/486.31/486.3/g`
	argument=`echo $argument | sed s/494.31/494.3/g`
    elif [ "`echo $argument | grep 1247035514.62  `" ]; then
	argument=`echo $argument | sed s/514.62/514.6/g`
	argument=`echo $argument | sed s/520.62/520.6/g`
    elif [ "`echo $argument | grep 1247041531.81  `" ]; then
	argument=`echo $argument | sed s/531.81/531.8/g`
	argument=`echo $argument | sed s/537.81/537.8/g`
    elif [ "`echo $argument | grep 1247035516.62  `" ]; then
	argument=`echo $argument | sed s/516.62/516.6/g`
	argument=`echo $argument | sed s/526.62/526.6/g`
    elif [ "`echo $argument | grep 1247042451.12  `" ]; then
	argument=`echo $argument | sed s/451.12/451.1/g`
	argument=`echo $argument | sed s/465.12/465.1/g`
    elif [ "`echo $argument | grep 1247029849.56  `" ]; then
	argument=`echo $argument | sed s/849.56/849.6/g`
	argument=`echo $argument | sed s/855.56/855.6/g`
    elif [ "`echo $argument | grep 1247043456.31  `" ]; then
	argument=`echo $argument | sed s/456.31/456.3/g`
	argument=`echo $argument | sed s/462.31/462.3/g`
    elif [ "`echo $argument | grep 1247043648.12  `" ]; then
	argument=`echo $argument | sed s/648.12/648.1/g`
	argument=`echo $argument | sed s/654.12/654.1/g`
    elif [ "`echo $argument | grep 1247043491.62  `" ]; then
	argument=`echo $argument | sed s/491.62/491.6/g`
	argument=`echo $argument | sed s/507.62/507.6/g`
    elif [ "`echo $argument | grep 1247029571.12  `" ]; then
	argument=`echo $argument | sed s/571.12/571.1/g`
	argument=`echo $argument | sed s/577.12/577.1/g`
    elif [ "`echo $argument | grep 1247030870.62  `" ]; then
	argument=`echo $argument | sed s/870.62/870.6/g`
	argument=`echo $argument | sed s/876.62/876.6/g`
    elif [ "`echo $argument | grep 1247043630.12  `" ]; then
	argument=`echo $argument | sed s/630.12/630.1/g`
	argument=`echo $argument | sed s/636.12/636.1/g`
    elif [ "`echo $argument | grep 1247043597.62  `" ]; then
	argument=`echo $argument | sed s/597.62/597.6/g`
	argument=`echo $argument | sed s/603.62/603.6/g`
    elif [ "`echo $argument | grep 1247043599.12  `" ]; then
	argument=`echo $argument | sed s/599.12/599.1/g`
	argument=`echo $argument | sed s/659.12/659.1/g`
    elif [ "`echo $argument | grep 1247043648.12  `" ]; then
	argument=`echo $argument | sed s/648.12/648.1/g`
	argument=`echo $argument | sed s/654.12/654.1/g`
    elif [ "`echo $argument | grep 1247043469.56  `" ]; then
	argument=`echo $argument | sed s/469.56/469.6/g`
	argument=`echo $argument | sed s/475.56/475.6/g`
    elif [ "`echo $argument | grep 1247031783.06  `" ]; then
	argument=`echo $argument | sed s/783.06/783.1/g`
	argument=`echo $argument | sed s/789.06/789.1/g`
    elif [ "`echo $argument | grep 1247035516.62  `" ]; then
	argument=`echo $argument | sed s/516.62/516.6/g`
	argument=`echo $argument | sed s/526.62/526.6/g`
    elif [ "`echo $argument | grep 1247035475.06  `" ]; then
	argument=`echo $argument | sed s/475.06/475.1/g`
	argument=`echo $argument | sed s/481.06/481.1/g`
    elif [ "`echo $argument | grep 1247034176.12  `" ]; then
	argument=`echo $argument | sed s/176.12/176.1/g`
	argument=`echo $argument | sed s/190.12/190.1/g`
    elif [ "`echo $argument | grep 1247030855.06  `" ]; then
	argument=`echo $argument | sed s/855.06/855.1/g`
	argument=`echo $argument | sed s/861.06/861.1/g`
    elif [ "`echo $argument | grep 1247035514.62  `" ]; then
	argument=`echo $argument | sed s/514.62/514.6/g`
	argument=`echo $argument | sed s/528.62/528.6/g`
    elif [ "`echo $argument | grep 1247042777.62  `" ]; then
	argument=`echo $argument | sed s/777.62/777.6/g`
	argument=`echo $argument | sed s/783.62/783.6/g`
    elif [ "`echo $argument | grep 1247042398.12  `" ]; then
	argument=`echo $argument | sed s/398.12/398.1/g`
	argument=`echo $argument | sed s/404.12/404.1/g`
    elif [ "`echo $argument | grep 1247035516.62  `" ]; then
	argument=`echo $argument | sed s/516.62/516.6/g`
	argument=`echo $argument | sed s/526.62/526.6/g`
    elif [ "`echo $argument | grep 1247043626.19  `" ]; then
	argument=`echo $argument | sed s/616.19/616.2/g`
	argument=`echo $argument | sed s/648.19/648.2/g`
    elif [ "`echo $argument | grep 1247043518.38  `" ]; then
	argument=`echo $argument | sed s/518.38/518.4/g`
	argument=`echo $argument | sed s/532.38/532.4/g`
    elif [ "`echo $argument | grep 1247042266.27  `" ]; then
	argument=`echo $argument | sed s/266.27/266.3/g`
	argument=`echo $argument | sed s/272.27/272.3/g`
    elif [ "`echo $argument | grep 1247040841.38  `" ]; then
	argument=`echo $argument | sed s/841.38/841.4/g`
	argument=`echo $argument | sed s/847.38/847.4/g`
    elif [ "`echo $argument | grep 1247043503.12  `" ]; then
	argument=`echo $argument | sed s/503.12/503.1/g`
	argument=`echo $argument | sed s/563.12/563.1/g`
    elif [ "`echo $argument | grep 1247043515.25  `" ]; then
	argument=`echo $argument | sed s/515.25/525.3/g`
	argument=`echo $argument | sed s/575.25/575.3/g`
    elif [ "`echo $argument | grep 1247043454.88  `" ]; then
	argument=`echo $argument | sed s/454.88/455/g`
	argument=`echo $argument | sed s/460.88/461/g`
    elif [ "`echo $argument | grep 1247043454.9  `" ]; then
	argument=`echo $argument | sed s/454.9/455/g`
	argument=`echo $argument | sed s/460.9/461/g`
    elif [ "`echo $argument | grep 1247043493.1  `" ]; then
	argument=`echo $argument | sed s/493.1/493/g`
	argument=`echo $argument | sed s/573.12/573/g`

    elif [ "`echo $argument | grep 1247042266.3  `" ]; then
	argument=`echo $argument | sed s/266.3/266/g`
	argument=`echo $argument | sed s/272.3/272/g`

    elif [ "`echo $argument | grep 1247043479.9  `" ]; then
	argument=`echo $argument | sed s/479.9/480/g`
	argument=`echo $argument | sed s/547.9/548/g`

    elif [ "`echo $argument | grep 1247029018.8  `" ]; then
	argument=`echo $argument | sed s/018.8/019/g`
	argument=`echo $argument | sed s/024.8/025/g`

    elif [ "`echo $argument | grep 1247043518.4  `" ]; then
	argument=`echo $argument | sed s/518.4/518/g`
	argument=`echo $argument | sed s/532.4/532/g`

    elif [ "`echo $argument | grep 1247035516.6  `" ]; then
	argument=`echo $argument | sed s/516.6/517/g`
	argument=`echo $argument | sed s/526.6/527/g`
    elif [ "`echo $argument | grep 1247024656.56  `" ]; then
	argument=`echo $argument | sed s/656.56/656.6/g`
	argument=`echo $argument | sed s/662.56/662.6/g`
    elif [ "`echo $argument | grep 1247025920.06  `" ]; then
	argument=`echo $argument | sed s/920.06/920.1/g`
	argument=`echo $argument | sed s/926.06/926.1/g`

    elif [ "`echo $argument | grep 1247029421.12  `" ]; then
	argument=`echo $argument | sed s/421.12/421.1/g`
	argument=`echo $argument | sed s/427.12/427.1/g`

    elif [ "`echo $argument | grep 1247039097.87  `" ]; then
	argument=`echo $argument | sed s/097.87/097.9/g`
	argument=`echo $argument | sed s/103.87/103.9/g`

    elif [ "`echo $argument | grep 1247038199.81  `" ]; then
	argument=`echo $argument | sed s/199.81/199.8/g`
	argument=`echo $argument | sed s/205.81/205.8/g`

    elif [ "`echo $argument | grep 1247043569.56  `" ]; then
	argument=`echo $argument | sed s/569.56/569.6/g`
	argument=`echo $argument | sed s/575.56/575.6/g`
    elif [ "`echo $argument | grep 1247043514.34  `" ]; then
	argument=`echo $argument | sed s/514.34/514/g`
	argument=`echo $argument | sed s/520.34/520/g`
    elif [ "`echo $argument | grep 1247043514.3  `" ]; then
	argument=`echo $argument | sed s/514.3/514/g`
	argument=`echo $argument | sed s/520.3/520/g`
    elif [ "`echo $argument | grep 1247043454.19  `" ]; then
	argument=`echo $argument | sed s/454.19/454/g`
	argument=`echo $argument | sed s/460.19/460/g`
    elif [ "`echo $argument | grep 1247043454.2  `" ]; then
	argument=`echo $argument | sed s/454.2/454/g`
	argument=`echo $argument | sed s/460.2/460/g`
    elif [ "`echo $argument | grep 1247024683.56  `" ]; then
	argument=`echo $argument | sed s/683.56/683.6/g`
	argument=`echo $argument | sed s/689.56/689.6/g`

    elif [ "`echo $argument | grep 1247043497.12  `" ]; then
	argument=`echo $argument | sed s/497.12/497.1/g`
	argument=`echo $argument | sed s/557.12/557.1/g`

    elif [ "`echo $argument | grep 1247043558.12  `" ]; then
	argument=`echo $argument | sed s/558.12/558.1/g`
	argument=`echo $argument | sed s/564.12/564.1/g`

    elif [ "`echo $argument | grep 1247033349.81  `" ]; then
	argument=`echo $argument | sed s/349.81/349.8/g`
	argument=`echo $argument | sed s/355.81/355.8/g`

    elif [ "`echo $argument | grep 1247043347.62  `" ]; then
	argument=`echo $argument | sed s/347.62/347.6/g`
	argument=`echo $argument | sed s/359.62/359.6/g`
    elif [ "`echo $argument | grep 1247033294.122  `" ]; then
	argument=`echo $argument | sed s/294.12/294.1/g`
	argument=`echo $argument | sed s/300.12/300.1/g`
    elif [ "`echo $argument | grep 1247035473.62  `" ]; then
	argument=`echo $argument | sed s/473.62/473.6/g`
	argument=`echo $argument | sed s/479.62/479.6/g`
COMMENTOUT
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
