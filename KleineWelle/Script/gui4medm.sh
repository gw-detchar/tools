#!/bin/bash
#******************************************#
#     File Name: KleineWelle/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/27 17:36:42
#******************************************#

################################
### Set variable
################################
CMD_KW=/usr/bin/kleineWelleM
DET_SYS=/users/DET
APP_DIR=${DET_SYS}/tools/KleineWelle/Script
RESULT_DIR=${DET_SYS}/Result/KleineWelle/medm
FILE_FFL=/users/DET/Cache/latest.ffl
source ${APP_DIR}/functions.sh


################################
### default value
################################
def_channel="*"
def_gpsstart=`gpstime | grep GPS | awk '{printf("%d\n", $2-600)}'`
def_duration=64
def_stride=16
def_transient=4
def_significance=2.0
def_threshold=3.0
def_decimate=-1.0
def_minfreq=16
def_maxfreq=1024

while :
do
    ################################
    ### GUI interface
    ################################
    flag=0
    while test ${flag} -eq 0
    do
	ZEN_OUT=`zenity --forms --text="KleineWelle${msg}" --separator=',' --add-entry="channel (${def_channel})" --add-entry="gps start (${def_gpsstart})" --add-entry="gps stop (start+${def_duration}s)" --add-entry="stride (${def_stride}s)" --add-entry="transientDuration (${def_transient}s)" --add-entry="significance (${def_significance})" --add-entry="threshold (${def_threshold})" --add-entry="decimateFactor (${def_decimate})" --add-entry="min freq. (${def_minfreq}Hz)" --add-entry="max freq. (${def_maxfreq}Hz)" 2> /dev/null`
	[ $? -eq 1 ] && exit 1
	
	channel=`printf "${ZEN_OUT}" | cut -d',' -f1`
	[ "${channel}" = "" -a "${def_channel}" != "*" ] && channel=${def_channel}
	[ "${channel}" != "" ] && def_channel=${channel}
	printf "channel: ${channel}\n" >&2 

	gpsstart=`printf "${ZEN_OUT}" | cut -d',' -f2`
	[ "${gpsstart}" = "" ] && gpsstart=${def_gpsstart} || def_gpsstart=${gpsstart}
	printf "gpsstart: ${gpsstart}\n" >&2 
	
	gpsstop=`printf "${ZEN_OUT}" | cut -d',' -f3`
	[ "${gpsstop}" = "" ] && let gpsstop=${gpsstart}+${def_duration} || let def_duration=${gpsstop}-${gpsstart}
	printf "gpsstop: ${gpsstop}\n" >&2

	stride=`printf "${ZEN_OUT}" | cut -d',' -f4`
	[ "${stride}" = "" ] && stride=${def_stride} || def_stride=${stride}
	printf "stride: ${stride}\n" >&2 

	transient=`printf "${ZEN_OUT}" | cut -d',' -f5`
	[ "${transient}" = "" ] && transient=${def_transient} || def_transient=${transient}
	printf "transient: ${transient}\n" >&2 

	significance=`printf "${ZEN_OUT}" | cut -d',' -f6`
	[ "${significance}" = "" ] && significance=${def_significance} || def_significance=${significance}
	printf "significance: ${significance}\n" >&2 

	threshold=`printf "${ZEN_OUT}" | cut -d',' -f7`
	[ "${threshold}" = "" ] && threshold=${def_threshold} || def_threshold=${threshold}
	printf "threshold: ${threshold}\n" >&2 

	decimate=`printf "${ZEN_OUT}" | cut -d',' -f8`
	[ "${decimate}" = "" ] && decimate=${def_decimate} || def_decimate=${decimate}
	printf "decimate: ${decimate}\n" >&2 

	minfreq=`printf "${ZEN_OUT}" | cut -d',' -f9`
	[ "${minfreq}" = "" ] && minfreq=${def_minfreq} || def_minfreq=${minfreq}
	printf "min freq.: ${minfreq}\n" >&2 

	maxfreq=`printf "${ZEN_OUT}" | cut -d',' -f10`
	[ "${maxfreq}" = "" ] && maxfreq=${def_maxfreq} || def_maxfreq=${maxfreq}
	printf "max freq.: ${maxfreq}\n" >&2 

	[ "${channel}" = "" -a "${def_channel}" = "*" ] && msg=": Channel is not selected." && continue
	[ ${def_duration} -le 0 -o ${def_duration} -gt 512 ] && msg=": \$(stop-start) must ranges from 1 to 512s." && continue
	[ ${def_stride} -le 0 -o ${def_stride} -gt ${def_duration} ] && msg=": stride must ranges from 1 to \$(stop-start)." && continue
	[ ${def_transient} -le 0 -o ${def_transient} -gt ${def_stride} ] && msg=": transientDuration must ranges from 1 to stride." && continue
	[ ${def_minfreq} -le 0 ] && msg=": min freq must be larger than 0Hz." && continue
	[ ${def_maxfreq} -le ${def_minfreq} ] && msg=": max freq must be larger than min freq." && continue
	flag=1
    done # end of while test flag

    ################################
    ### Calc. unique value
    ################################
    HOST=`hostname`
    TTY=`tty`
    echo $HOST
    echo $TTY
    md5=`printf "${channel}${gpsstart}${gpsstop}${stride}${transient}${significance}${threshold}${decimate}${minfreq}${maxfreq}${HOST}${TTY}" | md5sum | awk '{print $1}'`

    ################################
    ### Input check
    ################################
    OUTPUT_DIR=${RESULT_DIR}/${channel}/${gpsstart}-${def_duration}
    mkdir -p ${OUTPUT_DIR}

    ################################
    ### Parameter file generation
    ################################
    cat <<EOF > ${OUTPUT_DIR}/${md5}-param.txt
stride ${stride}
basename ${md5}
transientDuration ${transient}
significance ${significance}
threshold ${threshold}
decimateFactor ${decimate}
channel ${channel} ${minfreq} ${maxfreq} 2
EOF

    ################################
    ### File list generation
    ################################
    awk -v "a=${gpsstart}" -v "b=${gpsstop}" '{if($2>=a-31 && $2<b) print $1}' ${FILE_FFL} > ${OUTPUT_DIR}/${md5}-filelist.txt


    ################################
    ### Execute
    ################################
    cd ${OUTPUT_DIR}
    if test ! -e ${OUTPUT_DIR}/${md5}-trigger.txt
    then
	${CMD_KW} ${OUTPUT_DIR}/${md5}-param.txt -inlist ${OUTPUT_DIR}/${md5}-filelist.txt
	echo "# start_time stop_time time frequency unnormalized_energy normalized_energy chisqdof significance channel" > ${OUTPUT_DIR}/${md5}-trigger.txt
	cat ${OUTPUT_DIR}/${md5}-*/*.trg | grep -v '^#' >> ${OUTPUT_DIR}/${md5}-trigger.txt
    fi

    if test "`grep -v '^#' ${OUTPUT_DIR}/${md5}-trigger.txt`" = ""
    then
    	[ "$(ls ${OUTPUT_DIR}/${md5}-snr.png)" = "" ] && rm -fr ${OUTPUT_DIR}/${md5}-*
    	[ "$(ls ${OUTPUT_DIR})" = "" ] && rm -fr ${OUTPUT_DIR}
    	[ "$(ls ${RESULT_DIR}/${channel})" = "" ] && rm -fr ${RESULT_DIR}/${channel} && def_channel="*"
    	msg=": No tiriggers are found."
	continue
    fi

    gnuplot <<EOF
reset
set term png size 960,540
set output "${OUTPUT_DIR}/${md5}-snr.png"
set grid lc rgb "white" lt 2
set border lc rgb "white"
set title "${channel} (KleineWelle triggers)" tc rgb "white" font ",15"
set xrange [-${def_duration}*0.05:${def_duration}*1.05]
set yrange [${minfreq}*0.9:${maxfreq}*1.1]
set xlabel "time [s] since GPS:${gpsstart}" tc rgb "white" font ",15"
set ylabel "central frequency [Hz]" tc rgb "white" font ",15" offset 1, 0
set cblabel "SNR" tc rgb "white" font ",15"
set palette rgbformulae 22, 13, -31
set object 1 rect behind from screen 0,0 to screen 1,1 fc rgb "#333631" fillstyle solid 1.0
p "${OUTPUT_DIR}/${md5}-trigger.txt" u (\$3-${gpsstart}):4:(\$8*${def_duration}/5000):8 with circles notitle fs transparent solid 0.85 lw 2.0 pal
EOF
    eog ${OUTPUT_DIR}/${md5}-snr.png &
    [ "${SSH_CLIENT}" = "" ] && xdg-open ${OUTPUT_DIR} &

    msg=": Done."
done # end of while :
