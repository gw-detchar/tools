#!/bin/bash
#******************************************#
#     File Name: Omicron/printTriggers.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/04/04 19:43:32
#******************************************#

################################
### Set variable
################################
DET_ROOT=/users/DET
CMD_TRIGFIND=/home/controls/opt/summary-2.7/bin/gwtrigfind
ETG_DIR=/home/controls/triggers
ETG=OMICRON
FLAG_FULL=0

################################
### functions
################################
function __helpecho(){
cat <<EOF
Usage: $0 [-fl] [-t threshold] [-h] startgps stopgps channel
   Options:
      -f     Display full parameters
      -t     Set threshold of SNR
      -l     lower limit of frequency
      -h     Show this help
EOF
}

function __trigfind(){
    _startgps=$1
    _stopgps=$2
    _channel=`printf "${3#*:}" | tr '-' '_'`
    _ifo=${3%:*}
    
    let _startdir=${_startgps}/100000
    let _stopdir=${_stopgps}/100000
    let _currdir=${_startdir}
    while test ${_currdir} -le ${_stopdir}
    do
	ls ${ETG_DIR}/${_ifo}/${_channel}_${ETG}/${_currdir}/*.xml.gz
	let _currdir=${_currdir}+1
    done | awk -v s=${_startgps} -v e=${_stopgps} -F'-' '$3>=s && $3<=e{print $0}'
}

###################################################################################################
###################################################################################################
###   Main
###################################################################################################
###################################################################################################
while getopts fl:t:h opt
do
    case $opt in
	f) FLAG_FULL=1
	   ;;
	t) threshold=$OPTARG
	   ;;
	l) lower=${OPTARG}
	   ;;
	h) __helpecho && exit 0
	   ;;
	\?) __helpecho && exit 1
	    ;;
    esac
done
shift $((OPTIND - 1))

[ "${3}" = "" ] && __helpecho && printf "\n [\033[31m ERROR \033[00m] too few argments\n" && exit 1
[ "${threshold}" = "" ] && threshold=0
[ "${lower}" = "" ] && lower=0
startgps=${1}
stopgps=${2}
channel=${3}

if test -e ${CMD_TRIGFIND}
then
    LIST="`${CMD_TRIGFIND} ${channel} ${ETG} ${startgps} ${stopgps} | sed -e 's@file://@@g'`"
elif test -e ${ETG_DIR}
then
    LIST="`__trigfind ${startgps} ${stopgps} ${channel}`"
else
    printf "Can't find trigger files" && exit 1
fi


if test $FLAG_FULL = 0
then
    printf "%11s %13s %10s %10s %9s\n" "# peak_time" "peak_time_ns" "duration" "peak_freq" "snr"
    for trgfile in ${LIST}
    do
	zcat ${trgfile} | grep sngl_burst | grep ${ETG^^} | sed -e 's/"//g' | awk -v x=${threshold} -v s=${startgps} -v e=${stopgps} -v l=${lower} -F',' '$15>=x && $2>=s && $2<=e && $10>=l{printf("%11s %13s %10s %10s %9s\n", $2, $3, $6, $10, $15)}'
    done
else
    printf "%11s %13s %11s %14s %10s %10s %13s %10s %12s %9s\n" "# peak_time" "peak_time_ns" "start_time" "start_time_ns" "duration" "peak_freq" "central_freq" "bandwidth" "amplitude" "snr"
    for trgfile in ${LIST}
    do
	zcat ${trgfile} | grep sngl_burst | grep ${ETG^^} | sed -e 's/"//g' | awk -v x=${threshold} -v s=${startgps} -v e=${stopgps} -v l=${lower} -F',' '$15>=x && $2>=s && $2<=e && $10>=l{printf("%11s %13s %11s %14s %10s %10s %13s %10s %12s %9s\n",$2, $3, $4, $5, $6, $10, $11, $12, $14, $15)}'
    done
fi


########################
###  Memo
########################
# 1: ifo 
# 2: peak_time
# 3: peak_time_ns
# 4: start_time
# 5: start_time_ns
# 6: duration
# 7: search
# 8: proc_id
# 9: event_id
#10: peak_freq
#11: central_freq
#12: bandwidth
#13: channel
#14: amplitude
#15: snr
#16: confidence
#17: chisq
#18: chisq_dof
#19: param_one_name
#20: param_one_value
