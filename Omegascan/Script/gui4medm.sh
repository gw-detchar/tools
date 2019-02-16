#!/bin/bash
#******************************************#
#     File Name: Omegascan/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/28 21:46:17
#******************************************#

################################
### Set variable
################################
CMD_Omegascan=/home/controls/opt/summary-2.7/bin/gwdetchar-omega
DET_SYS=/users/DET
APP_DIR=${DET_SYS}/tools/Omegascan/Script
RESULT_DIR=${DET_SYS}/Result/Omegascan/medm
#FILE_FFL=${DET_SYS}/Cache/latest.ffl
#source ${APP_DIR}/functions.sh

################################
### Set variable
################################
if test "`hostname`" != "k1sumX"
then
    def_channel="*"
    def_gpsepoch=`gpstime | grep GPS | awk '{printf("%d\n", $2-300)}'`
    def_duration=16
    def_fsample=4096
    def_stride=4
    def_mismatch=0.2
    def_threshold=4
    def_minfreq=16
    def_maxfreq=1024
    def_minQ=4
    def_maxQ=100
fi

while :
do
    if test "`hostname`" != "k1sumX"
    then
    ################################
    ### GUI interface
    ################################
	flag=0
	while test ${flag} -eq 0
	do
	    ZEN_OUT=`zenity --forms --text="Omega-scan${msg}" --separator=',' --add-entry="channel (${def_channel})" --add-entry="gps epoch (${def_gpsepoch})" --add-entry="duration (${def_duration}s)" ---add-entry="fsample (${def_fsample}Hz)" --add-entry="stride (${def_stride}s)" --add-entry="mismatch (${def_mismatch})" --add-entry="threshold (${def_threshold})" --add-entry="min freq. (${def_minfreq}Hz)" --add-entry="max freq. (${def_maxfreq}Hz)" --add-entry="min Q (${def_minQ})" --add-entry="max Q (${def_maxQ})" 2> /dev/null`
	    [ $? -eq 1 ] && exit 1
    
	    channel=`printf "${ZEN_OUT}" | cut -d',' -f1`
	    [ "${channel}" = "" -a "${def_channel}" != "*" ] && channel=${def_channel}
	    [ "${channel}" != "" ] && def_channel=${channel}
	    printf "channel: ${channel}\n" >&2 

	    gpsepoch=`printf "${ZEN_OUT}" | cut -d',' -f2`
	    [ "${gpsepoch}" = "" ] && gpsepoch=${def_gpsepoch} || def_gpsepoch=${gpsepoch}
	    printf "gpsepoch: ${gpsepoch}\n" >&2 
    
	    duration=`printf "${ZEN_OUT}" | cut -d',' -f3`
	    [ "${duration}" = "" ] && duration=${def_duration} || def_duration=${duration}
	    printf "duration: ${duration}\n" >&2

	    fsample=`printf "${ZEN_OUT}" | cut -d',' -f4`
	    [ "${fsample}" = "" ] && fsample=${def_fsample} || def_fsample=${fsample}
	    printf "fsample: ${fsample}\n" >&2 

	    stride=`printf "${ZEN_OUT}" | cut -d',' -f5`
	    [ "${stride}" = "" ] && stride=${def_stride} || def_stride=${stride}
	    printf "stride: ${stride}\n" >&2 
	    
	    mismatch=`printf "${ZEN_OUT}" | cut -d',' -f6`
	    [ "${mismatch}" = "" ] && mismatch=${def_mismatch} || def_mismatch=${mismatch}
	    printf "mismatch: ${mismatch}\n" >&2 

	    threshold=`printf "${ZEN_OUT}" | cut -d',' -f7`
	    [ "${threshold}" = "" ] && threshold=${def_threshold} || def_threshold=${threshold}
	    printf "threshold: ${threshold}\n" >&2 
	    
	    minfreq=`printf "${ZEN_OUT}" | cut -d',' -f8`
	    [ "${minfreq}" = "" ] && minfreq=${def_minfreq} || def_minfreq=${minfreq}
	    printf "minfreq: ${minfreq}\n" >&2 

	    maxfreq=`printf "${ZEN_OUT}" | cut -d',' -f9`
	    [ "${maxfreq}" = "" ] && maxfreq=${def_maxfreq} || def_maxfreq=${maxfreq}
	    printf "min freq.: ${maxfreq}\n" >&2 

	    minQ=`printf "${ZEN_OUT}" | cut -d',' -f10`
	    [ "${minQ}" = "" ] && minQ=${def_minQ} || def_minQ=${minQ}
	    printf "min Q: ${minQ}\n" >&2 

	    maxQ=`printf "${ZEN_OUT}" | cut -d',' -f11`
	    [ "${maxQ}" = "" ] && maxQ=${def_maxQ} || def_maxQ=${maxQ}
	    printf "max Q: ${maxQ}\n" >&2 

	    [ "${channel}" = "" -a "${def_channel}" = "*" ] && msg=": Channel is not selected." && continue
	    [ ${def_duration} -le 0 -o ${def_duration} -gt 128 ] && msg=": \$(stop-start) must ranges from 1 to 128s." && continue
	    [ ${def_stride} -le 0 -o ${def_stride} -gt ${def_duration} ] && msg=": stride must ranges from 1 to \$(stop-start)." && continue
	    [ ${def_minfreq} -le 0 ] && msg=": min freq must be larger than 0Hz." && continue
	    [ ${def_maxfreq} -le ${def_minfreq} ] && msg=": max freq must be larger than min freq." && continue
	    [ ${def_maxfreq} -ge `expr ${def_fsample} / 2` ] && msg=": max freq must be smaller than Nyquist freq." && continue
	    [ ${def_minQ} -le 0 ] && msg=": min Q must be larger than 0." && continue
	    [ ${def_maxQ} -le ${def_minQ} ] && msg=": max Q must be larger than min freq." && continue
	    flag=1
	done # end of while test flag
	
	################################
	### Calc. unique value
	################################
	HOST=`hostname`
	TTY=`tty`
	echo $HOST
	echo $TTY
	md5=`printf "${channel}${gpsepoch}${duration}${fsample}${stride}${mismatch}${threshold}${minfreq}${maxfreq}${minQ}${maxQ}${HOST}${TTY}" | md5sum | awk '{print $1}'`

	################################
	### Input check
	################################
	let gpsstart=${gpsepoch}-${def_duration}/2
	OUTPUT_DIR=${RESULT_DIR}/${channel}/${gpsstart}-${def_duration}
	mkdir -p ${OUTPUT_DIR}/${md5}-results

	################################
	### Parameter file generation
	################################
	cat <<EOF > ${OUTPUT_DIR}/${md5}-param.txt
[GW]
name = Omega-scan ${channel}
q-range = ${minQ},${maxQ}
frequency-range = ${minfreq},${maxfreq}
resample = ${fsample}
frametype = K1_C
duration = ${duration}
fftlength = ${stride}
max-mismatch = ${mismatch}
snr-threshold = ${threshold}
always-plot = True
plot-time-durations = 1,${stride},${duration}
channels = ${channel}
EOF

	################################
	### Execute (move to k1sumX)
	################################
	export SSH_ASKPASS=/usr/lib/seahorse/seahorse-ssh-askpass
	setsid ssh -o NumberOfPasswordPrompts=1 -XY 10.68.10.252 ${APP_DIR}/gui4medm.sh ${channel} ${gpsepoch} ${duration} ${minfreq} ${maxfreq} ${OUTPUT_DIR} ${md5} 2> /dev/null
	
    else # if test k1sumX
	################################
	### Execute on k1sumX
	################################
	channel=${1}
	gpsepoch=${2}
	duration=${3}
	minfreq=${4}
	maxfreq=${5}
	OUTPUT_DIR=${6}
	md5=${7}
	let gpsstart=${gpsepoch}-${duration}/2

	if test ! -e ${OUTPUT_DIR}/${md5}-results/index.html
	then
	    ${CMD_Omegascan} -i K1 -o ${OUTPUT_DIR}/${md5}-results -f ${OUTPUT_DIR}/${md5}-param.txt -j 1 ${gpsepoch}
	fi

	exit 0
    fi # end of if test k1sumX

    firefox file://${OUTPUT_DIR}/${md5}-results/index.html &
    [ "${SSH_CLIENT}" = "" ] && xdg-open ${OUTPUT_DIR} &
    
    msg=": Done."
done # end of while :
