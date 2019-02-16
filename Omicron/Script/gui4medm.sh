#!/bin/bash
#******************************************#
#     File Name: Omicron/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/27 17:47:59
#******************************************#

################################
### Set variable
################################
CMD_Omicron=/home/controls/opt/virgosoft/Omicron/v2r3/Linux-x86_64/omicron.exe
DET_SYS=/users/DET
APP_DIR=${DET_SYS}/tools/Omicron/Script
RESULT_DIR=${DET_SYS}/Result/Omicron/medm
FILE_FFL=${DET_SYS}/Cache/latest.ffl
source ${APP_DIR}/functions.sh

################################
### Set variable
################################
if test "`hostname`" != "k1sumX"
then
    def_channel="*"
    def_gpsstart=`gpstime | grep GPS | awk '{printf("%d\n", $2-600)}'`
    def_duration=64
    def_fsample=2048
    def_stride=16
    def_overlap=1
    def_mismatch=0.2
    def_threshold=4
    def_psdlen=128
    def_minfreq=16
    def_maxfreq=1024
    def_minQ=4
    def_maxQ=100
    def_scan=OFF
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
	    ZEN_OUT=`zenity --forms --text="Omicron${msg}" --separator=',' --add-entry="channel (${def_channel})" --add-entry="gps start (${def_gpsstart})" --add-entry="gps stop (start+${def_duration}s)" --add-entry="fsample (${def_fsample}Hz)" --add-entry="stride (${def_stride}s)" --add-entry="overlap (${def_overlap}s)" --add-entry="mismatch (${def_mismatch})" --add-entry="threshold (${def_threshold})" --add-entry="psdlen (${def_psdlen}s)" --add-entry="min freq. (${def_minfreq}Hz)" --add-entry="max freq. (${def_maxfreq}Hz)" --add-entry="min Q (${def_minQ})" --add-entry="max Q (${def_maxQ})" --add-combo="scan (${def_scan})" --combo-values='OFF|ON' 2> /dev/null`
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

	    fsample=`printf "${ZEN_OUT}" | cut -d',' -f4`
	    [ "${fsample}" = "" ] && fsample=${def_fsample} || def_fsample=${fsample}
	    printf "fsample: ${fsample}\n" >&2 

	    stride=`printf "${ZEN_OUT}" | cut -d',' -f5`
	    [ "${stride}" = "" ] && stride=${def_stride} || def_stride=${stride}
	    printf "stride: ${stride}\n" >&2 
	    
	    overlap=`printf "${ZEN_OUT}" | cut -d',' -f6`
	    [ "${overlap}" = "" ] && overlap=${def_overlap} || def_overlap=${overlap}
	    printf "overlap: ${overlap}\n" >&2 
	    
	    mismatch=`printf "${ZEN_OUT}" | cut -d',' -f7`
	    [ "${mismatch}" = "" ] && mismatch=${def_mismatch} || def_mismatch=${mismatch}
	    printf "mismatch: ${mismatch}\n" >&2 

	    threshold=`printf "${ZEN_OUT}" | cut -d',' -f8`
	    [ "${threshold}" = "" ] && threshold=${def_threshold} || def_threshold=${threshold}
	    printf "threshold: ${threshold}\n" >&2 
	    
	    psdlen=`printf "${ZEN_OUT}" | cut -d',' -f9`
	    [ "${psdlen}" = "" ] && psdlen=${def_psdlen} || def_psdlen=${psdlen}
	    printf "psdlen: ${psdlen}\n" >&2 

	    minfreq=`printf "${ZEN_OUT}" | cut -d',' -f10`
	    [ "${minfreq}" = "" ] && minfreq=${def_minfreq} || def_minfreq=${minfreq}
	    printf "min freq.: ${minfreq}\n" >&2 

	    maxfreq=`printf "${ZEN_OUT}" | cut -d',' -f11`
	    [ "${maxfreq}" = "" ] && maxfreq=${def_maxfreq} || def_maxfreq=${maxfreq}
	    printf "max freq.: ${maxfreq}\n" >&2 

	    minQ=`printf "${ZEN_OUT}" | cut -d',' -f12`
	    [ "${minQ}" = "" ] && minQ=${def_minQ} || def_minQ=${minQ}
	    printf "min Q: ${minQ}\n" >&2 

	    maxQ=`printf "${ZEN_OUT}" | cut -d',' -f13`
	    [ "${maxQ}" = "" ] && maxQ=${def_maxQ} || def_maxQ=${maxQ}
	    printf "max Q: ${maxQ}\n" >&2 

	    scan=`printf "${ZEN_OUT}" | cut -d',' -f14`
	    [ "${scan}" = "" ] && scan=${def_scan} || def_scan=${scan}
	    printf "scan: ${scan}\n" >&2 

	    [ "${channel}" = "" -a "${def_channel}" = "*" ] && msg=": Channel is not selected." && continue
	    [ ${def_duration} -le 0 -o ${def_duration} -gt 512 ] && msg=": \$(stop-start) must ranges from 1 to 512s." && continue
	    [ ${def_stride} -le 0 -o ${def_stride} -gt ${def_duration} ] && msg=": stride must ranges from 1 to \$(stop-start)." && continue
	    [ ${def_minfreq} -le 0 ] && msg=": min freq must be larger than 0Hz." && continue
	    [ ${def_maxfreq} -le ${def_minfreq} ] && msg=": max freq must be larger than min freq." && continue
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
	md5=`printf "${channel}${gpsstart}${gpsstop}${fsample}${stride}${overlap}${mismatch}${threshold}${psdlen}${minfreq}${maxfreq}${minQ}${maxQ}${scan}${HOST}${TTY}" | md5sum | awk '{print $1}'`

	################################
	### Input check
	################################
	#let gpsepoch=${gpsstart}+${def_duration}/2
	OUTPUT_DIR=${RESULT_DIR}/${channel}/${gpsstart}-${def_duration}
	mkdir -p ${OUTPUT_DIR}/${md5}-results

	################################
	### Parameter file generation
	################################
	[ "${scan}" = ON ] && product=maps || product=""
	[ "${scan}" = ON ] && format=png || png=""
	cat <<EOF > ${OUTPUT_DIR}/${md5}-param.txt
DATA FFL ${FILE_FFL}
DATA CHANNELS ${channel}
DATA SAMPLEFREQUENCY ${fsample}

PARAMETER TIMING ${stride} ${overlap}
PARAMETER FREQUENCYRANGE ${minfreq} ${maxfreq}
PARAMETER QRANGE ${minQ} ${maxQ}
PARAMETER MISMATCHMAX ${mismatch}
PARAMETER SNRTHRESHOLD ${threshold}
PARAMETER PSDLENGTH ${psdlen}

OUTPUT DIRECTORY ${OUTPUT_DIR}/${md5}-results
OUTPUT PRODUCTS triggers ${product}
OUTPUT FORMAT txt ${format}
OUTPUT VERBOSIT 0
EOF
	
	################################
	### Execute (move to k1sumX)
	################################
	export SSH_ASKPASS=/usr/lib/seahorse/seahorse-ssh-askpass
	setsid ssh -o NumberOfPasswordPrompts=1 -nXY 10.68.10.252 ${APP_DIR}/gui4medm.sh ${channel} ${gpsstart} ${gpsstop} ${minfreq} ${maxfreq} ${OUTPUT_DIR} ${md5} 2> /dev/null
	
    else # if test k1sumX
	################################
	### Execute on k1sumX
	################################
	channel=${1}
	gpsstart=${2}
	gpsstop=${3}
	minfreq=${4}
	maxfreq=${5}
	OUTPUT_DIR=${6}
	md5=${7}
	let duration=${gpsstop}-${gpsstart}

	if test ! -e ${OUTPUT_DIR}/${md5}-trigger.txt
	then
	    ${CMD_Omicron} ${gpsstart} ${gpsstop} ${OUTPUT_DIR}/${md5}-param.txt
	    printf "# central time [s]\n# central frequency [Hz]\n# snr []\n# q []\n#amplitude [Hz^-1/2]\n# phase [rad]\n# starting time [s]\n# ending time [s]\n# staring frequency [Hz]\n# ending frequency [Hz]\n" > ${OUTPUT_DIR}/${md5}-trigger.txt
	    cat ${OUTPUT_DIR}/${md5}-results/${channel}/*.txt | grep -v '^#' >> ${OUTPUT_DIR}/${md5}-trigger.txt
	fi

	gnuplot <<EOF
reset
set term png size 960,540
set termoption noenhanced
set output "${OUTPUT_DIR}/${md5}-snr.png"
set grid lc rgb "white" lt 2
set border lc rgb "white"
set title "${channel} (Omicron triggers)" tc rgb "white" font ",15"
set xrange [-${duration}*0.05:${duration}*1.05]
set yrange [${minfreq}*0.9:${maxfreq}*1.1]
set xlabel "time since GPS:${gpsstart}" tc rgb "white" font ",15"
set ylabel "central frequency" tc rgb "white" font ",15" offset 1, 0
set cblabel "SNR" tc rgb "white" font ",15"
set palette rgbformulae 22, 13, -31
set object 1 rect behind from screen 0,0 to screen 1,1 fc rgb "#333631" fillstyle solid 1.0
p "${OUTPUT_DIR}/${md5}-trigger.txt" u (\$1-${gpsstart}):2:(\$3*${duration}/5000):3 with circles notitle fs transparent solid 0.85 lw 2.0 pal
EOF
	exit 0
    fi # end of if test k1sumX
    eog ${OUTPUT_DIR}/${md5}-snr.png ${OUTPUT_DIR}/${md5}-results/${channel}/*_OMICRONMAP-*.png &
    [ "${SSH_CLIENT}" = "" ] && xdg-open ${OUTPUT_DIR} &

    msg=": Done."

done # end of while :
