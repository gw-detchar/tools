#!/bin/bash
#******************************************#
#     File Name: iKozapy.sh
#        Author: Chihiro Kozakai
#******************************************#

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

################################
### Set variable
################################
def_channel1="K1:IMC-CAV_TRANS_OUT_DQ"
def_channel2=""
#def_gpstime=`gpstime | grep GPS | awk '{printf("%d\n", $2-300)}'`
def_realtime="n"
def_mode="s"
realtime=$def_realtime
def_duration=32
def_stride=1
def_bandwidth=1
def_minf=-1
def_maxf=8000
def_dpi=50
def_outdir="/tmp/detchar/iKozapy/Result/"
def_options=""
def_optionc=""
tmpoutdir="/users/DET/tools/iKozapy/Result/"

# following will be processed only in the first time in each machine. 
if [ ! -e ${def_outdir}/temp_spectrogram52.png ]; then
    for i in `seq 9`
    do
	rm -rf ${def_outdir}/temp_*gram1.png
	touch ${def_outdir}/temp_spectrogram${i}1.png
	touch ${def_outdir}/temp_spectrogram${i}2.png
	touch ${def_outdir}/temp_coherencegram${i}1.png
    done

fi

s1png=`ls -t /tmp/detchar/iKozapy/Result/temp_spectrogram*1.png | tail -1`
s2png=`ls -t /tmp/detchar/iKozapy/Result/temp_spectrogram*2.png | tail -1`
c1png=`ls -t /tmp/detchar/iKozapy/Result/temp_coherencegram*1.png | tail -1`


fl=0

while :
do 
    #def_gpsend=`gpstime | grep GPS | awk '{printf("%d\n", $2)}'`
    def_gpsend=`${cmd_gps} | grep JST | awk '{printf("%s %s\n", $2, $3)}'`
  
    #    while test ${flag} -eq 0
    if [ "${realtime}" != "y" ]; then

	[ -e /usr/bin/xclip ] && printf "${def_gpsend}" | xclip
	ZEN_OUT=`zenity --forms --text="iKozapy plot tool" --separator=',' --add-entry="Spectrogram or coherencegram [s/c] (${def_mode})" --add-entry="channel1 (${def_channel1})" --add-entry="channel2 for coherencegram(${def_channel2})" --add-entry="JST or GPS end time (${def_gpsend})"  --add-entry="Real time update ? [y/n] (n)"  --add-entry="Duration [sec] (${def_duration})" --add-entry="Time resolution [sec] (${def_stride})"  --add-entry="Frequency resolution [Hz] (${def_bandwidth})" --add-entry="min. f [Hz] (autoscale)" --add-entry="max. f [Hz] (autoscale)" --add-entry="png resolution [dpi] (50)" --add-entry="Other option for spectrogram" --add-entry="Other option for coherencegram" `
	#ZEN_OUT=`zenity --forms --text="iKozapy for spectrogram${msg}" --separator=',' --add-entry="main channel (${def_channel})" --add-entry="gps end time (${def_gpsend})"  --add-entry="Now ? [y/n] (n)"  --add-entry="Duration [sec] (${def_duration})" --add-entry="Time resolution [sec] (${def_stride})"  --add-entry="Frequency resolution [Hz] (${def_bandwidth})" --add-entry="min. f [Hz] (autoscale)" --add-entry="max. f [Hz] (autoscale)" --add-entry="png resolution [dpi] (50)" --add-entry="Other option" `
	[ $? -eq 1 ] && exit 1

	mode=`printf "${ZEN_OUT}" | cut -d',' -f1 `
	[ "${mode}" = ""  ] && mode=${def_mode}
	[ "${mode}" != "" ] && def_mode=${mode}
	printf "mode: ${mode} \n" >&2
	[ "${mode}" != "s" ] && [ "${mode}" != "c" ] && [ "${mode}" != "sc" ] && [ "${mode}" != "cs" ] && zenity --error --title Error --text "Invalid mode ! Please use 's' or 'c'. " && continue
		
	#channel=`printf "${ZEN_OUT}" | cut -d',' -f1 | sed -e 's/K1://g'`
	channel1=`printf "${ZEN_OUT}" | cut -d',' -f2 `
	[ "${channel1}" = ""  ] && channel1=${def_channel1}
	[ "${channel1}" != "" ] && def_channel1=${channel1}
	printf "channel1: ${channel1} \n" >&2
		
	channel2=`printf "${ZEN_OUT}" | cut -d',' -f3 `
	[ "${channel2}" = ""  ] && channel2=${def_channel2}
	[ "${channel2}" != "" ] && def_channel2=${channel2}
	printf "channel2: ${channel2} \n" >&2
		
#	gpsstart=`printf "${ZEN_OUT}" | cut -d',' -f2`
#	[ "${gpsstart}" = "" ] && gpsstart=${def_gpsstart} || def_gpsstart=${gpsstart}
#	printf "gpsstart: ${gpsstart}\n" >&2
	
	gpsend=`printf "${ZEN_OUT}" | cut -d',' -f4`
	[ "${gpsend}" = "" ] && gpsend=${def_gpsend} || def_gpsend=${gpsend}
	gpsend=`${cmd_gps} $gpsend| grep GPS | awk '{printf("%d\n", $2)}'`
	printf "gpsend: ${gpsend}\n" >&2
	[ ! -e /frame0/full/${gpsend:0:5} ]  && zenity --error --title Error --text "Data doesn't exist in Kamioka. Please go to Kashiwa server. " && continue

	realtime=`printf "${ZEN_OUT}" | cut -d',' -f5`
	[ "${realtime}" = "" ] && realtime=${def_realtime} || def_realtime=${realtime}
	printf "realtime: ${realtime}\n" >&2
	[ "${realtime}" != "y" ] && [ "${realtime}" != "n" ] && zenity --error --title Error --text "Invalid option in real time update ! Please use 'y' or 'n'. " && continue

	duration=`printf "${ZEN_OUT}" | cut -d',' -f6`
	[ "${duration}" = "" ] && duration=${def_duration} || def_duration=${duration}
	printf "duration: ${duration}\n" >&2

	gpsstart=$(( $gpsend - $duration ))
	
	stride=`printf "${ZEN_OUT}" | cut -d',' -f7`
	[ "${stride}" = "" ] && stride=${def_stride} || def_stride=${stride}
	printf "stride: ${stride}\n" >&2
	if [ "$(echo "$duration < $stride" | bc)" -eq 1 ]; then
	    zenity --error --title Error --text "Duration must be longer than time resolution ! "
	    continue
	fi
	
	bandwidth=`printf "${ZEN_OUT}" | cut -d',' -f8`
	[ "${bandwidth}" = "" ] && bandwidth=${def_bandwidth} || def_bandwidth=${bandwidth}
	printf "bandwidth: ${bandwidth}\n" >&2
	fft=`echo "scale=5; 1. / $bandwidth" | bc `
	if [ "$(echo "$fft > $stride" | bc)" -eq 1 ]; then
	    zenity --error --title Error --text "Time resolution > 1/Frequency resolution is required ! "
	    continue
	fi

	
	minf=`printf "${ZEN_OUT}" | cut -d',' -f9`
	[ "${minf}" = "" ] && minf=${def_minf} || def_minf=${minf}
	printf "minf: ${minf}\n" >&2

	maxf=`printf "${ZEN_OUT}" | cut -d',' -f10`
	[ "${maxf}" = "" ] && maxf=${def_maxf} || def_maxf=${maxf}
	printf "maxf: ${maxf}\n" >&2
		
	dpi=`printf "${ZEN_OUT}" | cut -d',' -f11`
	[ "${dpi}" = "" ] && dpi=${def_dpi} || def_dpi=${dpi}
	printf "dpi: ${dpi}\n" >&2
		
	options=`printf "${ZEN_OUT}" | cut -d',' -f12`
	[ "${options}" = "" ] && options=${def_options} || def_options=${options}
	printf "options: ${options}\n" >&2
		
	optionc=`printf "${ZEN_OUT}" | cut -d',' -f13`
	[ "${optionc}" = "" ] && optionc=${def_optionc} || def_optionc=${optionc}
	printf "optionc: ${optionc}\n" >&2
		
    fi

    if [ "${realtime}" = "y" ]; then
	gpsend=`gpstime | grep GPS | awk '{printf("%d\n", $2)}'`
	gpsstart=$(( $gpsend - $duration ))
    fi

    fft=`echo "scale=5; 1. / $bandwidth" | bc `

    if [ ! -e ${def_outdir} ]; then
	mkdir -p ${def_outdir}
    fi

    if [ "`echo $mode | grep s `" ]; then
	ssh -i /home/controls/.ssh/id_ed25519_detchar -o StrictHostKeyChecking=no -Y controls@k1det0 /users/DET/tools/GlitchPlot/Script/Kozapy/samples/run_whitening_spectrogram.sh -s ${gpsstart} -e ${gpsend} -c ${channel1} --kamioka --stride ${stride} -f ${fft}  -o ${tmpoutdir} --dpi ${dpi} --fmin ${minf} --fmax ${maxf} ${option} > ${def_outdir}/tmp 2>&1

	success=$(tail -n 1 ${def_outdir}/tmp)
	if test "$success" = "Successfully finished !" ;then
	    output=$(tail -n 2 ${def_outdir}/tmp | head -n 1) 

	    echo $output
	    echo ${def_outdir}
	    #mv $output ${def_outdir}/${s1png}
	    mv $output ${s1png}
	    if [ -e ${output} ]; then
		rm -rf ${output}
	    fi    
	    sleep 1s    
	    #eog ${def_outdir}/temp_spectrogram1.png -w &
	    eog ${s1png} -w &
	    
	else
#	    echo "job failes."
	    #	    echo `tail  ${def_outdir}/tmp `
	    errormessage=`tail  ${def_outdir}/tmp `
	    zenity --error --title Error --text "Job failed. Full log is in ${def_outdir}/tmp. \n $errormessage "
	fi

#	if test "$channel2" != "" ;then
#	    ssh -i /home/controls/.ssh/id_ed25519_detchar -o StrictHostKeyChecking=no -Y controls@k1det0 /users/DET/tools/GlitchPlot/Script/Kozapy/samples/run_whitening_spectrogram.sh -s ${gpsstart} -e ${gpsend} -c ${channel2} --kamioka --stride ${stride} -f ${fft}  -o ${tmpoutdir} --dpi ${dpi} --fmin ${minf} --fmax ${maxf} ${option} > ${def_outdir}/tmp 2>&1

#	    success=$(tail -n 1 ${def_outdir}/tmp)
#	    if test "$success" = "Successfully finished !" ;then
#		output=$(tail -n 2 ${def_outdir}/tmp | head -n 1) 

#		echo $output
#		echo ${def_outdir}
#		mv $output ${s2png}
#		if [ -e ${output} ]; then
#		    rm -rf ${output}
#		fi    
#		sleep 1s    
	#	eog ${s2png} -w &

#	    else
#		echo "job failes."
#		echo `tail  ${def_outdir}/tmp `
#	    fi
	    
#	fi #  if test "$channel2" != "" ;then
    fi # if [ "`echo $mode | grep s `" ]; then

    if [ "`echo $mode | grep c `" ]; then
	ssh -i /home/controls/.ssh/id_ed25519_detchar -o StrictHostKeyChecking=no -Y controls@k1det0 /users/DET/tools/GlitchPlot/Script/Kozapy/samples/run_coherencegram.sh -s ${gpsstart} -e ${gpsend} -r ${channel1} -c ${channel2} --kamioka --stride ${stride} -f ${fft}  -o ${tmpoutdir} --dpi ${dpi} --fmin ${minf} --fmax ${maxf} ${option} > ${def_outdir}/tmp 2>&1

	success=$(tail -n 1 ${def_outdir}/tmp)
	if test "$success" = "Successfully finished !" ;then
	    output=$(tail -n 2 ${def_outdir}/tmp | head -n 1) 

	    echo $output
	    echo ${def_outdir}
	    mv $output ${c1png}
	    if [ -e ${output} ]; then
		rm -rf ${output}
	    fi    
	    sleep 1s    
	    eog ${c1png} -w &
	    
	else
	    echo "job failes."
	    echo `tail  ${def_outdir}/tmp `
	fi
    fi # if [ "`echo $mode | grep c `" ]; then
    
done & # end of while :

bg=$!

(
    echo "0"
) |
zenity --text="Do you want to stop iKozapy ?" --progress --percentage=0
tmp=$?


kill $bg
kill $$


