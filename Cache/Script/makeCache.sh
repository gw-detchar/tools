#!/bin/bash
#set -e
#******************************************#
#     File Name: makeCache.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2026/03/02 12:05:43
#******************************************#

############################################
### Helper function
############################################
function _usage(){
    cat <<EOF
usage:
  > $0 [-d] -c cluster -t type [-i interval] arg1 [arg2]

options:
  -d         : Debug-mode (override OUTPUT_DIR as ${HOME}/Desktop/cache)
  -c cluster : Kamioka, Kashiwa
  -t type    : full, science, second, minute, LL, LLNoGap
  -i interval: exec interval in the unit of seconds

examples:
  LL-mode:
    > $0 [-d] -c cluster -t {LL,LLNoGap} [-i interval] {K1,L1,H1,V1}
    ### make cache for LL frames
      
  Online-mode:
    > $0 [-d] -c cluster -t {full,science,second,minute} [-i interval] 0 [clean]
    ### make cache for recent GPS directories
    ###   with cleaing up caches of removed fromes if "clean" is given as arg2

  Directory-mode:
    > $0 [-d] -c cluster -t {full,science,second,minute} gps_dir0 [gps_dir1]
    ### make cache for GPS directories
    ###  for [gps_dir0, gps_dir1] or for gps_dir0 if gps_dir1 is NOT given
      
  File-mode:
    > $0 [-d] -c cluster -t {full,science,second,minute} gps0 gps1
    ### make cache for Raw frames
    ###   in [int(gps0/file_len)*file_len, int((gps1-1)/file_len+1)*file_len)

EOF
}

function __uniq_files(){
    local current=$1
    local root1=$2
    local root2=$3
    if test "${root2}" != ""
    then
	let COL=$(printf "${root1}/${current}/" | tr '/' '\n' | wc -l)+1
	CHAR=$(printf "${root1}/${current}/" | wc -c)
	local old=$(shopt -p nullglob)
	shopt -s nullglob
	printf "%s\n" ${root2}/${current}/*.gwf ${root1}/${current}/*.gwf | sort -s -t '/' -k${COL},${COL} | uniq -s ${CHAR}
	eval "${old}"
    else
	ls -1 ${root1}/${current}/*.gwf
    fi
}

############################################
### Options
############################################
while getopts c:dhi:t: OPT; do
    case $OPT in
	c) CLUSTER=$OPTARG;;
	d) DEBUG_MODE="True";;
	t) TYPE=$OPTARG;;
	i) INTERVAL=$OPTARG;;
	h) _usage; exit 1;;
	:) _usage; exit 1;;
	*) _usage; exit 1;;
    esac
done
shift $((OPTIND - 1))

### Cluster (-c)
if test "${CLUSTER}" = "Kamioka"
then
    GWF_ROOT0=/frame0
    GWF_ROOT1=/frame1
    ROOTDIR=/users/DET/Cache
elif test "${CLUSTER}" = "Kashiwa"
then
    GWF_ROOT0=/data/KAGRA/raw
    GWF_ROOT1=""
    ROOTDIR=${HOME}/cache
else
    _usage
    exit 1
fi

### Debug mode (-d)
if test "${DEBUG_MODE}" = "True"
then
    ROOTDIR=${HOME}/Desktop/cache
    echo "Debug-mode: override ROOTDIR as ${ROOTDIR}"
fi

### Frame Type (-t)
DIR_LEN=100000
if test "${TYPE}" = "" -o "${TYPE}" = "full"
then
    GWF_DIR0=${GWF_ROOT0}/full
    GWF_LEN=32
    GWF_TYPE=K1_C
    OUT_DIR=${ROOTDIR}/Cache_GPS
    LATESTFILE=latest
elif test "${TYPE}" = "science"
then
    GWF_DIR0=${GWF_ROOT0}/science
    GWF_LEN=32
    GWF_TYPE=K1_R
    OUT_DIR=${ROOTDIR}/CacheScience_GPS
    LATESTFILE=latest_science
elif test "${TYPE}" = "second"
then
    GWF_DIR0=${GWF_ROOT0}/trend/second
    GWF_LEN=600
    GWF_TYPE=K1_T
    OUT_DIR=${ROOTDIR}/CacheSecond_GPS
    LATESTFILE=latest_second
elif test "${TYPE}" = "minute"
then
    GWF_DIR0=${GWF_ROOT0}/trend/minute
    GWF_LEN=3600
    GWF_TYPE=K1_M
    OUT_DIR=${ROOTDIR}/CacheMinute_GPS
    LATESTFILE=latest_minute
elif test "${TYPE}" = "LL" -o "${TYPE}" = "LLNoGap"
then
    GWF_DIR0=/data/LVK/low-latency/ll_merged
    GWF_LEN=4096
    GWF_TYPE=llohft
    OUT_DIR=${ROOTDIR}/Cache_LL
else
    _usage
    exit 1
fi

if test "${GWF_ROOT1}" != ""
then
    GWF_DIR1=$(printf "${GWF_DIR0}" | sed -e "s|${GWF_ROOT0}|${GWF_ROOT1}|g")
else
    GWF_DIR1=""
fi

### Exec interval (-i)
if test "${INTERVAL}" = ""
then
    INTERVAL=$(( ${GWF_LEN} > 120 ? ${GWF_LEN} : 120 ))
fi
let CHECK_WINDOW=${INTERVAL}+${INTERVAL}/2

############################################
### Main
############################################
if test "${1}" = ""
then
    _usage
    exit 0
    
elif test "${TYPE}" = "LL"
then
    if test -d ${GWF_DIR0}/${1}
    then
	echo "Create ${OUT_DIR}/${1}.{ffl,cache}"
	mkdir -p ${OUT_DIR}
	ls -1 ${GWF_DIR0}/${1}/*.gwf \
            | awk -F'[-.]' '{printf("%s\t%s %s  0 0\n", $0, $4, $5)}' > ${OUT_DIR}/${1}.ffl
	awk -v T=${1}_${GWF_TYPE} '{printf("%c %s %s %s file://localhost%s\n", T, T, $2, $3, $1)}' ${OUT_DIR}/${1}.ffl \
    	    > ${OUT_DIR}/${1}.cache
    else
	echo "Can't find ${GWF_DIR0}/${1}"
    fi

elif test "${TYPE}" = "LLNoGap"
then
    if test -d ${GWF_DIR0}/${1}_NoGap
    then
	echo "Create ${OUT_DIR}/${1}_NoGap.{ffl,cache}"
	mkdir -p ${OUT_DIR}
	ls -1 ${GWF_DIR0}/${1}_NoGap/*.gwf \
            | awk -F'[-.]' '{printf("%s\t%s %s  0 0\n", $0, $4, $5)}' > ${OUT_DIR}/${1}_NoGap.ffl
	awk -v T=${1}_${GWF_TYPE}NoGap '{printf("%c %s %s %s file://localhost%s\n", T, T, $2, $3, $1)}' ${OUT_DIR}/${1}_NoGap.ffl \
    	    > ${OUT_DIR}/${1}_NoGap.cache
    else
	echo "Can't find ${GWF_DIR0}/${1}_NoGap"
    fi
    
elif test "${1}" -eq 0
then
    if test "${2}" = "clean"
    then
	for cc in ${OUT_DIR}/*.ffl
	do
	    gpsdir=$(basename ${cc} .ffl)
	    if test "${GWF_DIR1}" = "" -a ! -e ${GWF_DIR0}/${gpsdir}
	    then
		dd=$(dirname ${cc})/$(basename ${cc} .ffl)
		echo "Remove ${dd}.{ffl,cache}"
		rm -f ${cc} ${dd}.cache
	    elif test ! -e ${GWF_DIR0}/${gpsdir} -a ! -e ${GWF_DIR1}/${gpsdir}
	    then
		dd=$(dirname ${cc})/$(basename ${cc} .ffl)
		echo "Remove ${dd}.{ffl,cache}"
		rm -f ${cc} ${dd}.cache
	    fi
	done
    fi

    ##########################################
    ### online-mode
    ##########################################
    CURR_GPS=$(gpstime -g -f "%d")
    echo "GPS time: ${CURR_GPS} ($(gpstime -l ${CURR_GPS} -f "%F %H:%M:%S %Z"))"
    let CURR_FILE=${CURR_GPS}/${GWF_LEN}\*${GWF_LEN}
    let CURR_DIR=${CURR_FILE}/${DIR_LEN}

    let RESIDUAL=${CURR_GPS}-$(gpstime -g $(gpstime -l ${CURR_GPS} -f "%F %H:00:00 %Z") -f "%d")
    let PREV_DIR_1=${CURR_DIR}-1
    if test ! -e ${OUT_DIR}/${CURR_DIR}.ffl
    then
	let PREV_DIR_0=${PREV_DIR_1}-1
	msg="Create"
    elif test ${RESIDUAL} -ge 30 -a ${RESIDUAL} -lt ${CHECK_WINDOW}
    then
	PREV_DIR_0=${PREV_DIR_1}
	msg="Update"
    else
	let PREV_DIR_0=${PREV_DIR_1}+1
	msg="Update"
    fi

    ### previous GPS directories
    for PREV_DIR in $(seq ${PREV_DIR_0} ${PREV_DIR_1})
    do
	if test -e ${GWF_DIR0}/${PREV_DIR} -o -e ${GWF_DIR1}/${PREV_DIR}
	then
	    LSOUT=$(__uniq_files ${PREV_DIR} ${GWF_DIR0} ${GWF_DIR1})
	    if test $(echo "${LSOUT}" | wc -l) != $(cat ${OUT_DIR}/${PREV_DIR}.ffl 2>/dev/null | wc -l)
	    then
		echo "Update ${OUT_DIR}/${PREV_DIR}.{ffl,cache}"
		mkdir -p ${OUT_DIR}
		echo "${LSOUT}" \
		    | awk -F'[-.]' '{printf("%s\t%s %s  0 0\n", $0, $3, $4)}' > ${OUT_DIR}/${PREV_DIR}.ffl
		awk -v T=${GWF_TYPE} '{printf("%c %s %s %s file://localhost%s\n", T, T, $2, $3, $1)}' ${OUT_DIR}/${PREV_DIR}.ffl \
		    > ${OUT_DIR}/${PREV_DIR}.cache
	    fi
	else
	    echo "Can't find ${GWF_DIR0}/${PREV_DIR}"
	fi
    done

    ### current GPS directory
    if test -e ${GWF_DIR0}/${CURR_DIR} -o -e ${GWF_DIR1}/${CURR_DIR}
    then
	LSOUT=$(__uniq_files ${CURR_DIR} ${GWF_DIR0} ${GWF_DIR1})
	echo "${msg} ${OUT_DIR}/${CURR_DIR}.{ffl,cache}"
	mkdir -p ${OUT_DIR}
	echo "${LSOUT}" \
	    | awk -F'[-.]' '{printf("%s\t%s %s  0 0\n", $0, $3, $4)}' > ${OUT_DIR}/${CURR_DIR}.ffl
	awk -v T=${GWF_TYPE} '{printf("%c %s %s %s file://localhost%s\n", T, T, $2, $3, $1)}' ${OUT_DIR}/${CURR_DIR}.ffl \
	    > ${OUT_DIR}/${CURR_DIR}.cache
    else
	echo "Can't find ${GWF_DIR0}/${CURR_DIR}"
    fi

    ### latest 7-days cache
    echo "Update $(dirname ${OUT_DIR})/${LATESTFILE}.{ffl,cache}"
    cat $(ls ${OUT_DIR}/*.ffl | tail -7) > $(dirname ${OUT_DIR})/${LATESTFILE}.ffl
    cat $(ls ${OUT_DIR}/*.cache | tail -7) > $(dirname ${OUT_DIR})/${LATESTFILE}.cache


elif test "${1}" -lt ${DIR_LEN}
then
    ##########################################
    ### gps-dir-mode
    ##########################################
    START_DIR=${1}
    if test "${2}" = ""
    then
	let STOP_DIR=${START_DIR}
    elif test "${2}" -lt ${DIR_LEN}
    then
	STOP_DIR=${2}
    else
	exit 1
    fi

    for ii in $(seq ${START_DIR} ${STOP_DIR})
    do
	if test -e ${GWF_DIR0}/${ii} -o -e ${GWF_DIR1}/${ii}
	then
	    LSOUT=$(__uniq_files ${ii} ${GWF_DIR0} ${GWF_DIR1})
	    echo "Create ${OUT_DIR}/${ii}.{ffl,cache}"
	    mkdir -p ${OUT_DIR}
	    echo "${LSOUT}" \
		| awk -F'[-.]' '{printf("%s\t%s %s  0 0\n", $0, $3, $4)}' > ${OUT_DIR}/${ii}.ffl
	    awk -v T=${GWF_TYPE} '{printf("%c %s %s %s file://localhost%s\n", T, T, $2, $3, $1)}' ${OUT_DIR}/${ii}.ffl \
		> ${OUT_DIR}/${ii}.cache
	else
	    echo "Can't find ${GWF_DIR0}/${ii}"
	fi
    done

elif test "${1}" -ge ${DIR_LEN}
then
    ##########################################
    ### gps-file-mode
    ##########################################
    let START_DIR=${1}/${DIR_LEN}
    let LL=${1}/${GWF_LEN}\*${GWF_LEN}
    if test "${2}" = ""
    then
	exit 1
    elif test "${2}" -le "${1}"
    then
	exit 1
    else
	let STOP_DIR=${2}/${DIR_LEN}
	let HH=(${2}-1)/${GWF_LEN}\*${GWF_LEN}
    fi

    for ii in $(seq ${START_DIR} ${STOP_DIR})
    do
	echo $ii
	if test -e ${GWF_DIR0}/${ii} -o -e ${GWF_DIR1}/${ii}
	then
	    LSOUT=$(__uniq_files ${ii} ${GWF_DIR0} ${GWF_DIR1})
	    echo "Create ${OUT_DIR}/${LL}_${HH}.{ffl,cache}"
	    mkdir -p ${OUT_DIR}
	    echo "${LSOUT}" \
		| awk -F'[-.]' -v ll=${LL} -v hh=${HH} '{if(ll<=$3 && $3<=hh) printf("%s\t%s %s  0 0\n", $0, $3, $4)}' \
		      > ${OUT_DIR}/${LL}_${HH}.ffl
	    awk -v T=${GWF_TYPE} '{printf("%c %s %s %s file://localhost%s\n", T, T, $2, $3, $1)}' ${OUT_DIR}/${LL}_${HH}.ffl \
		> ${OUT_DIR}/${LL}_${HH}.cache
	else
	    echo "Can't find ${GWF_DIR0}/${ii}"
	fi
    done
fi

############################################
### EOF
############################################
