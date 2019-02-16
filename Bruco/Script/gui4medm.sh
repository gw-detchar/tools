#!/bin/bash
#******************************************#
#     File Name: Bruco/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/24 14:21:36
#******************************************#

DET_SYS=/users/DET
DET_BRUCO=${DET_SYS}/tools/Bruco
APP_DIR=${DET_BRUCO}/Script
CONF_DIR=${DET_BRUCO}/share
RESULT_DIR=${DET_SYS}/Result/Bruco/medm
CMD_BRUCO=/users/bruco/bruco.py

while test "${channel}" = "" -o "${gpstime}" = ""
do
    ZEN_OUT=`zenity --forms --text="Bruco${msg}" --separator=',' --add-entry='main channel(*)' --add-entry='gps time(*)' --add-entry='duration[s]' --add-entry='n_average' --add-entry='out_fs[Hz]' --add-entry='min_fs[Hz]' --add-entry='n_display' --add-combo='filter(excl.)' --combo-values='include|exclude' --add-entry='create excl. list' 2> /dev/null`
    [ $? -eq 1 ] && exit 1

    channel=`printf "${ZEN_OUT}" | cut -d',' -f1 | sed -e 's/K1://g'`
    [ "${channel}" = "" ] && msg=": Can't read channel" && continue
    printf "channel: ${channel}\n" >&2 

    gpstime=`printf "${ZEN_OUT}" | cut -d',' -f2`
    [ "${gpstime}" = "" ] && msg=": Can't read gpstime" && continue
    printf "gpstime: ${gpstime}\n" >&2 

    duration=`printf "${ZEN_OUT}" | cut -d',' -f3`
    [ "${duration}" = "" ] && duration=32
    [ ${duration} -gt 900 ] && duration=900
    printf "duration: ${duration}\n" >&2 

    n_ave=`printf "${ZEN_OUT}" | cut -d',' -f4`
    [ "${n_ave}" = "" -a ${duration} -le 1 ] && n_ave=2
    [ "${n_ave}" = "" -a ${duration} -gt 1 ] && n_ave=${duration}
    printf "n_ave: ${n_ave}\n" >&2 

    outfs=`printf "${ZEN_OUT}" | cut -d',' -f5`
    [ "${outfs}" = "" ] && outfs=2048
    printf "outfs: ${outfs}\n" >&2 

    minfs=`printf "${ZEN_OUT}" | cut -d',' -f6`
    [ "${minfs}" = "" ] && minfs=1024
    printf "minfs: ${minfs}\n" >&2 

    n_disp=`printf "${ZEN_OUT}" | cut -d',' -f7`
    [ "${n_disp}" = "" ] && n_disp=5
    let n_top=${n_disp}+5
    printf "n_disp: ${n_disp}\n" >&2 

    filter=`printf "${ZEN_OUT}" | cut -d',' -f8`
    [ "${filter}" = " " ] && filter="exclude"
    printf "filter: ${filter}\n" >&2 


    create=`printf "${ZEN_OUT}" | cut -d',' -f9`
    printf "create: ${create}\n" >&2 
done


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
xterm -e bash -c "python ${CMD_BRUCO} --ifo=K1 --channel=${channel} --${filter}=\"${exclude}\" --gpsb=${gpstime} --length=${duration} --outfs=${outfs} --minfs=${minfs} --naver=${n_ave} --dir=${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration} --top=${n_top} --webtop=${n_disp} >&2 || sleep 15" && firefox ${RESULT_DIR}/${channel}-${base_excl}/${gpstime}-${duration}/index.html
# --xlim=10:1000
