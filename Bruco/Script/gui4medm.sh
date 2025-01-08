#!/bin/bash
#******************************************#
#     File Name: Bruco/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2023/07/12 20:52:29
#******************************************#

################################
### Set variable
################################
DET_SYS=/users/DET
DET_BRUCO=${DET_SYS}/tools/Bruco
APP_DIR=${DET_BRUCO}/Script
CONF_DIR=${DET_BRUCO}/share
RESULT_DIR=${DET_SYS}/Result/Bruco/medm
if test -e "/etc/debian_version" -a `cut -d'.' -f1 /etc/debian_version` = "8"
then
    version="deb8"
    CMD_BRUCO=/users/bruco/bruco.py
    echo "${version}"
else
    CMD_BRUCO=bruco
fi

################################
### Set variable
################################
def_channel="LSC-DARM_IN1_DQ"
def_gpstime=`gpstime -g -f "%d" | awk '{printf("%d", $1-400)}'`
def_date=`gpstime -u -f "%Y-%m-%d" ${def_gpstime}`
def_time=`gpstime -u -f "%H:%M:%S" ${def_gpstime}`
def_zone="UTC"
def_duration=128
def_n_ave=32
def_outfs=2048
def_minfs=512
def_n_disp=30
def_filter="exclude"


while :
do
    flag=0
    while test ${flag} -eq 0
    do
	[ -e /usr/bin/xclip ] && printf "${def_gpstime}" | xclip
	ZEN_OUT=`zenity --forms --text="Bruco${msg}" --separator=',' --add-entry="main channel (${def_channel})" --add-entry="gps time (${def_gpstime})" --add-entry="    date (${def_date})" --add-entry="    time (${def_time})" --add-combo="    zone (${def_zone})" --combo-values='UTC|JST' --add-entry="duration[s] (${def_duration})" --add-entry="n_average (${def_n_ave})" --add-entry="out_fs[Hz] (${def_outfs})" --add-entry="min_fs[Hz] (${def_minfs})" --add-entry="n_display (${def_n_disp})" --add-combo="filter (${def_filter})" --combo-values='include|exclude' --add-entry='create excl. list' 2> /dev/null`
	[ $? -eq 1 ] && exit 1

	channel=`printf "${ZEN_OUT}" | cut -d',' -f1 | sed -e 's/K1://g'`
	[ "${channel}" = "" -a "${def_channel}" != "*" ] && channel=${def_channel}
	[ "${channel}" != "" ] && def_channel=${channel}
	printf "channel: ${channel} ${def_channel}\n" >&2 

	gpstime=`printf "${ZEN_OUT}" | cut -d',' -f2`
	if test "${gpstime}" != ""
	then
	    zdate=`gpstime -u -f "%Y-%m-%d" ${gpstime}`
	    ztime=`gpstime -u -f "%H:%M:%S" ${gpstime}`
	    zone="UTC"
	    def_gpstime=${gpstime}
	    def_date=${zdate}
	    def_time=${ztime}
	    def_zone=${zone}
	else
	    zdate=`printf "${ZEN_OUT}" | cut -d',' -f3`
	    ztime=`printf "${ZEN_OUT}" | cut -d',' -f4`
	    zone=`printf "${ZEN_OUT}" | cut -d',' -f5`
	    [ "${zdate}" = "" ] && zdate=${def_date} || def_date=${zdate}
	    [ "${ztime}" = "" ] && ztime=${def_time} || def_time=${ztime}
	    [ "${zone}" = " " ] && zone=${def_zone} || def_zone=${zone}
	    gpstime=`gpstime -g -f "%d" "${zdate} ${ztime} ${zone}" | awk '{printf("%d", $1)}'`
	    def_gpstime=${gpstime}
	fi
	[ "${gpstime}" = "" ] && gpstime=${def_gpstime} || def_gpstime=${gpstime}
	printf "gpstime: ${gpstime}\n" >&2 
	printf "   date: ${zdate} ${ztime} ${zone}\n" >&2 

	duration=`printf "${ZEN_OUT}" | cut -d',' -f6`
	[ "${duration}" = "" ] && duration=${def_duration} || def_duration=${duration}
	printf "duration: ${duration}\n" >&2 

	n_ave=`printf "${ZEN_OUT}" | cut -d',' -f7`
	[ "${n_ave}" = "" ] && n_ave=${def_n_ave} || def_n_ave=${n_ave}
	[ "${n_ave}" = "" -a ${duration} -le 1 ] && n_ave=2
	[ "${n_ave}" = "" -a ${duration} -gt 1 ] && n_ave=${duration}
	printf "n_ave: ${n_ave}\n" >&2 

	outfs=`printf "${ZEN_OUT}" | cut -d',' -f8`
	[ "${outfs}" = "" ] && outfs=${def_outfs} || def_outfs=${outfs}
	printf "outfs: ${outfs}\n" >&2 

	minfs=`printf "${ZEN_OUT}" | cut -d',' -f9`
	[ "${minfs}" = "" ] && minfs=${def_minfs} || def_minfs=${minfs}
	printf "minfs: ${minfs}\n" >&2 

	n_disp=`printf "${ZEN_OUT}" | cut -d',' -f10`
	[ "${n_disp}" = "" ] && n_disp=${def_n_disp} || def_n_disp=${n_disp}
	let n_top=${n_disp}+5
	printf "n_disp: ${n_disp}\n" >&2 

	filter=`printf "${ZEN_OUT}" | cut -d',' -f11`
	[ "${filter}" = " " ] && filter=${def_filter} || def_filter=${filter}
	printf "filter: ${filter}\n" >&2 

	create=`printf "${ZEN_OUT}" | cut -d',' -f12`
	printf "create: ${create}\n" >&2 

	[ "${channel}" = "" -a "${def_channel}" = "*" ] && msg=": Channel is not selected." && continue
	[ ${def_duration} -le 0 -o ${def_duration} -gt 4000 ] && msg=": duration must ranges from 1 to 4000s." && continue
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
    
    if test "${channel}" = "CAL-CS_PROC_MICH_DISPLACEMENT_DQ"
    then
	DOF="MICH"
    elif test "${channel}" = "CAL-CS_PROC_PRCL_DISPLACEMENT_DQ"
    then
	DOF="PRCL"
    elif test "${channel}" = "CAL-CS_PROC_DARM_DISPLACEMENT_DQ"
    then
	DOF="DARM"
    else
	DOF=""
    fi

    if test "${version}" = "deb8"
    then
	if test "${DOF}" != ""
	then
    	    xterm -e bash -c "python ${CMD_BRUCO} --ifo=K1 --channel=${channel} --${filter}=\"${exclude}\" --gpsb=${gpstime} --length=${duration} --outfs=${outfs} --minfs=${minfs} --naver=${n_ave} --dir=${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration} --top=${n_top} --webtop=${n_disp} >&2 || sleep 300" && bash -c "cd ${RESULT_DIR} && unlink latest && ln -s ./${channel}-${base_excl}/${gpstime}-${duration} latest && unlink latest_${DOF} && ln -s ./${channel}-${base_excl}/${gpstime}-${duration} latest_${DOF} && firefox ${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration}/index.html"
	else
    	    xterm -e bash -c "python ${CMD_BRUCO} --ifo=K1 --channel=${channel} --${filter}=\"${exclude}\" --gpsb=${gpstime} --length=${duration} --outfs=${outfs} --minfs=${minfs} --naver=${n_ave} --dir=${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration} --top=${n_top} --webtop=${n_disp} >&2 || sleep 300" && bash -c "cd ${RESULT_DIR} && unlink latest && ln -s ./${channel}-${base_excl}/${gpstime}-${duration} latest && firefox ${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration}/index.html"
	fi
    else
	if test "${DOF}" != ""
	then
    	    xterm -e bash -c "source /kagra/apps/etc/conda3-user-env_deb10.sh && conda activate bruco-py39 && ${CMD_BRUCO} --ifo=K1 --channel=${channel} --${filter}=\"${exclude}\" --gpsb=${gpstime} --length=${duration} --outfs=${outfs} --minfs=${minfs} --naver=${n_ave} --dir=${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration} --top=${n_top} --webtop=${n_disp} >&2 || sleep 300" && bash -c "cd ${RESULT_DIR} && unlink latest && ln -s ./${channel}-${base_excl}/${gpstime}-${duration} latest && unlink latest_${DOF} && ln -s ./${channel}-${base_excl}/${gpstime}-${duration} latest_${DOF} && firefox ${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration}/index.html" 
	else
    	    xterm -e bash -c "source /kagra/apps/etc/conda3-user-env_deb10.sh && conda activate bruco-py39 && ${CMD_BRUCO} --ifo=K1 --channel=${channel} --${filter}=\"${exclude}\" --gpsb=${gpstime} --length=${duration} --outfs=${outfs} --minfs=${minfs} --naver=${n_ave} --dir=${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration} --top=${n_top} --webtop=${n_disp} >&2 || sleep 300" && bash -c "cd ${RESULT_DIR} && unlink latest && ln -s ./${channel}-${base_excl}/${gpstime}-${duration} latest && firefox ${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration}/index.html" 
	fi
    fi
    msg=": Done."
done # end of while :
