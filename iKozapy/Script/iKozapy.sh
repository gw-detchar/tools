#!/bin/bash
#******************************************#
#     File Name: iKozapy.sh
#        Author: Chihiro Kozakai
#******************************************#


################################
### Set variable
################################
def_channel="K1:IMC-CAV_TRANS_OUT_DQ"
#def_gpstime=`gpstime | grep GPS | awk '{printf("%d\n", $2-300)}'`
def_realtime="n"
realtime=$def_realtime
def_duration=32
def_stride=1
def_bandwidth=1
def_minf=-1
def_maxf=8000
def_dpi=50
def_outdir="/tmp/detchar/iKozapy/Result/"
def_option=""
tmpoutdir="/users/DET/tools/iKozapy/Result/"

fl=0

while :
do 
    def_gpsend=`gpstime | grep GPS | awk '{printf("%d\n", $2)}'`
  
    flag=0
    #    while test ${flag} -eq 0
    #    if [ "${realtime}" = "n" ]; then
    if [ "true" ]; then
    

	[ -e /usr/bin/xclip ] && printf "${def_gpsend}" | xclip
	#ZEN_OUT=`zenity --forms --text="iKozapy for spectrogram${msg}" --separator=',' --add-entry="main channel (${def_channel})" --add-entry="gps end time (${def_gpsend})"  --add-entry="Real time update ? [y/n] (n)"  --add-entry="Duration [sec] (${def_duration})" --add-entry="Time resolution [sec] (${def_stride})"  --add-entry="Frequency resolution [Hz] (${def_bandwidth})" --add-entry="min. f [Hz] (autoscale)" --add-entry="max. f [Hz] (autoscale)" --add-entry="png resolution [dpi] (50)" --add-entry="Other option" `
	ZEN_OUT=`zenity --forms --text="iKozapy for spectrogram${msg}" --separator=',' --add-entry="main channel (${def_channel})" --add-entry="gps end time (${def_gpsend})"  --add-entry="Now ? [y/n] (n)"  --add-entry="Duration [sec] (${def_duration})" --add-entry="Time resolution [sec] (${def_stride})"  --add-entry="Frequency resolution [Hz] (${def_bandwidth})" --add-entry="min. f [Hz] (autoscale)" --add-entry="max. f [Hz] (autoscale)" --add-entry="png resolution [dpi] (50)" --add-entry="Other option" `
	[ $? -eq 1 ] && exit 1
	
	#channel=`printf "${ZEN_OUT}" | cut -d',' -f1 | sed -e 's/K1://g'`
	channel=`printf "${ZEN_OUT}" | cut -d',' -f1 `
	[ "${channel}" = ""  ] && channel=${def_channel}
	[ "${channel}" != "" ] && def_channel=${channel}
	printf "channel: ${channel} \n" >&2
		
#	gpsstart=`printf "${ZEN_OUT}" | cut -d',' -f2`
#	[ "${gpsstart}" = "" ] && gpsstart=${def_gpsstart} || def_gpsstart=${gpsstart}
#	printf "gpsstart: ${gpsstart}\n" >&2
	
	gpsend=`printf "${ZEN_OUT}" | cut -d',' -f2`
	[ "${gpsend}" = "" ] && gpsend=${def_gpsend} || def_gpsend=${gpsend}
	printf "gpsend: ${gpsend}\n" >&2

	realtime=`printf "${ZEN_OUT}" | cut -d',' -f3`
	[ "${realtime}" = "" ] && realtime=${def_realtime} || def_realtime=${realtime}
	printf "realtime: ${realtime}\n" >&2
	
	duration=`printf "${ZEN_OUT}" | cut -d',' -f4`
	[ "${duration}" = "" ] && duration=${def_duration} || def_duration=${duration}
	printf "duration: ${duration}\n" >&2

	gpsstart=$(( $gpsend - $duration ))
	
	stride=`printf "${ZEN_OUT}" | cut -d',' -f5`
	[ "${stride}" = "" ] && stride=${def_stride} || def_stride=${stride}
	printf "stride: ${stride}\n" >&2
	
	bandwidth=`printf "${ZEN_OUT}" | cut -d',' -f6`
	[ "${bandwidth}" = "" ] && bandwidth=${def_bandwidth} || def_bandwidth=${bandwidth}
	printf "bandwidth: ${bandwidth}\n" >&2
	
	minf=`printf "${ZEN_OUT}" | cut -d',' -f7`
	[ "${minf}" = "" ] && minf=${def_minf} || def_minf=${minf}
	printf "minf: ${minf}\n" >&2

	maxf=`printf "${ZEN_OUT}" | cut -d',' -f8`
	[ "${maxf}" = "" ] && maxf=${def_maxf} || def_maxf=${maxf}
	printf "maxf: ${maxf}\n" >&2
		
	dpi=`printf "${ZEN_OUT}" | cut -d',' -f9`
	[ "${dpi}" = "" ] && dpi=${def_dpi} || def_dpi=${dpi}
	printf "dpi: ${dpi}\n" >&2
		
	option=`printf "${ZEN_OUT}" | cut -d',' -f10`
	[ "${option}" = "" ] && option=${def_option} || def_option=${option}
	printf "option: ${option}\n" >&2
		
	
	[ "${channel}" = "" -a "${def_channel}" = "*" ] && msg=": Channel is not selected." && continue
	#[ ${def_duration} -le 0 -o ${def_duration} -gt 900 ] && msg=": duration must ranges from 1 to 900s." && continue
	flag=1
#    done # end of while test flag
    fi

    if [ "${realtime}" = "y" ]; then
	gpsend=`gpstime | grep GPS | awk '{printf("%d\n", $2)}'`
	gpsstart=$(( $gpsend - $duration ))
    fi
    fft=`echo "scale=5; 1. / $bandwidth" | bc `

    if [ ! -e ${def_outdir} ]; then
	mkdir -p ${def_outdir}
    fi

    ssh -i /home/controls/.ssh/id_ed25519_detchar -o StrictHostKeyChecking=no -Y controls@k1det0 /users/DET/tools/GlitchPlot/Script/Kozapy/samples/run_whitening_spectrogram.sh -s ${gpsstart} -e ${gpsend} -c ${channel} --kamioka --stride ${stride} -f ${fft}  -o ${tmpoutdir} --dpi ${dpi} --fmin ${minf} --fmax ${maxf} ${option} > ${def_outdir}/tmp 2>&1
    
    output=$(tail -n 2 ${def_outdir}/tmp | head -n 1) 

    
    mv $output ${def_outdir}/temp.png

    sleep 1s
#    if [ $fl = 0 ]; then
    
    eog ${def_outdir}/temp.png -w &
#	fl=1
#    fi
	#msg=": Done."

    #break
done # end of while :

