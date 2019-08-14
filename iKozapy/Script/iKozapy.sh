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
def_gpsstart=`gpstime | grep GPS | awk '{printf("%d\n", $2-64)}'`
def_gpsend=`gpstime | grep GPS | awk '{printf("%d\n", $2-32)}'`
def_duration=32
def_fres=1
def_stride=1
def_fft=1

while :
do
   
    flag=0
    while test ${flag} -eq 0
    do
	[ -e /usr/bin/xclip ] && printf "${def_gpstime}" | xclip
	ZEN_OUT=`zenity --forms --text="iKozapy for spectrogram${msg}" --separator=',' --add-entry="main channel (${def_channel})" --add-entry="gps start time (${def_gpsstart})" --add-entry="gps end time (${def_gpsend})" --add-entry="stride (${def_stride})"  --add-entry="FFT length[s] (${def_fft})" `
	[ $? -eq 1 ] && exit 1
	
	#channel=`printf "${ZEN_OUT}" | cut -d',' -f1 | sed -e 's/K1://g'`
	channel=`printf "${ZEN_OUT}" | cut -d',' -f1 `
	[ "${channel}" = ""  ] && channel=${def_channel}
	[ "${channel}" != "" ] && def_channel=${channel}
	printf "channel: ${channel} \n" >&2
		
	gpsstart=`printf "${ZEN_OUT}" | cut -d',' -f2`
	[ "${gpsstart}" = "" ] && gpsstart=${def_gpsstart} || def_gpsstart=${gpsstart}
	printf "gpsstart: ${gpsstart}\n" >&2
	
	gpsend=`printf "${ZEN_OUT}" | cut -d',' -f3`
	[ "${gpsend}" = "" ] && gpsend=${def_gpsend} || def_gpsend=${gpsend}
	printf "gpsend: ${gpsend}\n" >&2
	
	stride=`printf "${ZEN_OUT}" | cut -d',' -f4`
	[ "${stride}" = "" ] && stride=${def_stride} || def_stride=${stride}
	printf "stride: ${stride}\n" >&2
	
	fft=`printf "${ZEN_OUT}" | cut -d',' -f5`
	[ "${fft}" = "" ] && fft=${def_fft} || def_fft=${fft}
	printf "fft: ${fft}\n" >&2
	
	
	[ "${channel}" = "" -a "${def_channel}" = "*" ] && msg=": Channel is not selected." && continue
	#[ ${def_duration} -le 0 -o ${def_duration} -gt 900 ] && msg=": duration must ranges from 1 to 900s." && continue
	flag=1
    done # end of while test flag

    ssh -i /home/controls/.ssh/id_ed25519_detchar -o StrictHostKeyChecking=no -Y controls@k1det0 /users/DET/tools/GlitchPlot/Script/Kozapy/samples/run_whitening_spectrogram.sh -s ${gpsstart} -e ${gpsend} -c ${channel} --kamioka --stride ${stride} -f ${fft}  -o /users/DET/tools/iKozapy/Result/ > /users/DET/tools/iKozapy/Script/tmp 2>&1

    output=$(tail -n 2 /users/DET/tools/iKozapy/Script/tmp | head -n 1) 

    mkdir -p /tmp/detchar/iKozapy/Result
    mv $output /tmp/detchar/iKozapy/Result/temp.png

    eog /tmp/detchar/iKozapy/Result/temp.png &
    #msg=": Done."

    #break
done # end of while :

