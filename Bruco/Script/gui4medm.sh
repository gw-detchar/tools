#!/bin/bash
#******************************************#
#     File Name: Bruco/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/07/20 22:06:20
#******************************************#

################################
### Set variable
################################
DET_SYS=/users/DET
DET_BRUCO=${DET_SYS}/tools/Bruco
APP_DIR=${DET_BRUCO}/Script
CONF_DIR=${DET_BRUCO}/share
RESULT_DIR=${DET_SYS}/Result/Bruco/medm
CMD_BRUCO=/users/bruco/bruco.py

################################
### Set variable
################################
def_channel="*"
def_gpstime=`gpstime | grep GPS | awk '{printf("%d\n", $2-300)}'`
def_duration=32
def_n_ave=10
def_outfs=2048
def_minfs=1024
def_n_disp=5
def_filter="exclude"


while :
do
    flag=0
    while test ${flag} -eq 0
    do
	[ -e /usr/bin/xclip ] && printf "${def_gpstime}" | xclip
	ZEN_OUT=`zenity --forms --text="Bruco${msg}" --separator=',' --add-entry="main channel (${def_channel})" --add-entry="gps time (${def_gpstime})" --add-entry="duration[s] (${def_duration})" --add-entry="n_average (${def_n_ave})" --add-entry="out_fs[Hz] (${def_outfs})" --add-entry="min_fs[Hz] (${def_minfs})" --add-entry="n_display (${def_n_disp})" --add-combo="filter (${def_filter})" --combo-values='include|exclude' --add-entry='create excl. list' 2> /dev/null`
	[ $? -eq 1 ] && exit 1

	channel=`printf "${ZEN_OUT}" | cut -d',' -f1 | sed -e 's/K1://g'`
	[ "${channel}" = "" -a "${def_channel}" != "*" ] && channel=${def_channel}
	[ "${channel}" != "" ] && def_channel=${channel}
	printf "channel: ${channel} ${def_channel}\n" >&2 

	gpstime=`printf "${ZEN_OUT}" | cut -d',' -f2`
	[ "${gpstime}" = "" ] && gpstime=${def_gpstime} || def_gpstime=${gpstime}
	printf "gpstime: ${gpstime}\n" >&2 

	duration=`printf "${ZEN_OUT}" | cut -d',' -f3`
	[ "${duration}" = "" ] && duration=${def_duration} || def_duration=${duration}
	printf "duration: ${duration}\n" >&2 

	n_ave=`printf "${ZEN_OUT}" | cut -d',' -f4`
	[ "${n_ave}" = "" -a ${duration} -le 1 ] && n_ave=2
	[ "${n_ave}" = "" -a ${duration} -gt 1 ] && n_ave=${duration}
	printf "n_ave: ${n_ave}\n" >&2 

	outfs=`printf "${ZEN_OUT}" | cut -d',' -f5`
	[ "${outfs}" = "" ] && outfs=${def_outfs} || def_outfs=${outfs}
	printf "outfs: ${outfs}\n" >&2 

	minfs=`printf "${ZEN_OUT}" | cut -d',' -f6`
	[ "${minfs}" = "" ] && minfs=${def_minfs} || def_minfs=${minfs}
	printf "minfs: ${minfs}\n" >&2 

	n_disp=`printf "${ZEN_OUT}" | cut -d',' -f7`
	[ "${n_disp}" = "" ] && n_disp=${def_n_disp} || def_n_disp=${n_disp}
	let n_top=${n_disp}+5
	printf "n_disp: ${n_disp}\n" >&2 

	filter=`printf "${ZEN_OUT}" | cut -d',' -f8`
	[ "${filter}" = " " ] && filter=${def_filter} || def_filter=${filter}
	printf "filter: ${filter}\n" >&2 

	create=`printf "${ZEN_OUT}" | cut -d',' -f9`
	printf "create: ${create}\n" >&2 

	[ "${channel}" = "" -a "${def_channel}" = "*" ] && msg=": Channel is not selected." && continue
	[ ${def_duration} -le 0 -o ${def_duration} -gt 900 ] && msg=": duration must ranges from 1 to 900s." && continue
	[ ${def_outfs} -le 0 ] && msg=": outfs must be larger than 0Hz." && continue
	[ ${def_minfs} -le 0 -o ${def_minfs} -gt ${def_outfs} ] && msg=": minfs must ranges from 0 to outfs[Hz]." && continue
	flag=1
    done # end of while test flag


    if test "${create}" = ""
    then
    	exclude=`zenity --file-selection --filename=${CONF_DIR}/ 2> /dev/null`
    elif test `basename "${create}"` = "${create}"
    then
    	${APP_DIR}/create_exclude_list.sh | tee ${CONF_DIR}/${create}
    	exclude=`zenity --file-selection --filename=${CONF_DIR}/${create} 2> /dev/null`
    else
    	${APP_DIR}/create_exclude_list.sh | tee ${create}
    	exclude=`zenity --file-selection --filename=${create} 2> /dev/null`
    fi
    [ "${exclude}" = "" ] && exclude="${CONF_DIR}/bruco_excluded_channels.txt"


    base_excl=`basename ${exclude} .txt`
    mkdir -p ${RESULT_DIR}/${channel}-${base_excl}
    xterm -e bash -c "python ${CMD_BRUCO} --ifo=K1 --channel=${channel} --${filter}=\"${exclude}\" --gpsb=${gpstime} --length=${duration} --outfs=${outfs} --minfs=${minfs} --naver=${n_ave} --dir=${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration} --top=${n_top} --webtop=${n_disp} >&2 || sleep 300" && firefox ${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration}/index.html
    # # --xlim=10:1000

    msg=": Done."
done # end of while :
