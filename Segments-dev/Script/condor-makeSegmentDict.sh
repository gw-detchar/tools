#!/bin/bash
#set -e
#******************************************#
#     File Name: condor-makeCache.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2026/07/30 12:57:23
#******************************************#

############################################
###  User variables
############################################
JOBNUM=10 ### +/-4
EXECUTABLE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/makeSegmentDict.py
LOGDIR=${HOME}/log

############################################
###  Helper functions
############################################
function _usage(){
    msg=${1}
    if test "${msg}" != ""
    then
	msg="[ ERROR ] ${msg}"
    fi
    cat<<EOF
usage: $0 [-s] [-g gap] [-o output_dir] [-d] 0
usage: $0 [-s] [-g gap] [-o output_dir] [-d] dir0 [dir1]
usage: $0 [-s] [-g gap] [-o output_dir] [-d] gps0 gps1

options:
    -s: submit to condor
    -g: gap treatment ['pad', 'unknown']
    -o: output directory
    -d: debug-mode

arguments:
    dir0, dir1: [Int] dir0 <= dir1 <= 99999
    gps0, gps1: [Int] gps0 < gps1

${msg}
EOF
}

############################################
###  Arguments
############################################
while getopts sdg:o:h OPT; do
    case $OPT in
	s) SUBMIT="True";;
	d) DEBUG="--dry-run --no-read";;
	g) GAP="${OPTARG}";;
	o) OUTPUT="--output ${OPTARG}";;
	h) _usage; exit 0;;
	:) _usage; exit 1;;
	*) _usage; exit 1;;
    esac
done
shift $((OPTIND - 1))

if test "${GAP}" = "pad" -o "${GAP}" = "unknown"
then
    GAP="--gap ${GAP}"
fi

############################################
###  Submission file
############################################
SDF=$(cat <<EOF
Universe   = vanilla
Notification = never
request_memory = 1GB
Getenv  = True
EOF
      )

###  Online-mode
if test "${1}" = ""
then
    _usage
    exit 1
elif test ${1} -eq 0
then
    if test $(whoami) = "detchar"
    then
	SDF=$(cat <<EOF
${SDF}
accounting_group = group_priority
EOF
	   )
    fi
    SDF=$(cat <<EOF
${SDF}

cron_minute    = */10
OnExitRemove   = false

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} --cluster Kashiwa ${GAP} ${OUTPUT} --online
Output     = ${LOGDIR}/makeSegmentDict-online_\$(Cluster).txt
Error      = ${LOGDIR}/makeSegmentDict-online_\$(Cluster).err

Queue
EOF
       )

###  directory-mode
elif test ${1} -lt 100000
then
    if test "${2}" = ""
    then
	DIR0=${1}
	let DIR1=${DIR0}+1
	SDF=$(cat <<EOF
${SDF}

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} --cluster Kashiwa ${GAP} ${OUTPUT} --fill ${DIR0}00000 ${DIR1}00000
Output     = ${LOGDIR}/makeSegmentDict-manual_${DIR0}.txt
Error      = ${LOGDIR}/makeSegmentDict-manual_${DIR0}.err

Queue
EOF
	   )
    elif test ${2} -lt 100000 -a ${1} -le ${2}
    then
	SDF=$(cat <<EOF
${SDF}

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} --cluster Kashiwa ${GAP} ${OUTPUT} --fill \$(DIR0)00000 \$(DIR1)00000
Output     = ${LOGDIR}/makeSegmentDict-manual_\$(DIR0)_\$(DIR1).txt
Error      = ${LOGDIR}/makeSegmentDict-manual_\$(DIR0)_\$(DIR1).err

Queue DIR0, DIR1 from (
EOF
	   )
	let stop=${2}+1
	let diff=${stop}-${1}
	let chunk=(${diff}+${JOBNUM}-1)/${JOBNUM}
	for dir0 in $(seq ${1} ${chunk} ${2})
	do
	    let dir1=${dir0}+${chunk}
	    if test ${dir1} -ge ${stop}
	    then
		dir1=${stop}
	    fi
	    SDF=$(cat <<EOF
${SDF}
      ${dir0} ${dir1}
EOF
	       )
	done
	SDF=$(cat <<EOF
${SDF}
)
EOF
	   )
    else
	_usage
	exit 1
    fi

###  file-mode
elif test ${1} -ge 100000
then
    if test  "${2}" = ""
    then
	_usage "gps1 is required"
	exit 1
    elif test ${2} -ge ${1}
    then
	SDF=$(cat <<EOF
${SDF}

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} --cluster Kashiwa ${GAP} ${OUTPUT} --fill ${1} ${2}
Output     = ${LOGDIR}/makeSegmentDict-manual_${1}_${2}.txt
Error      = ${LOGDIR}/makeSegmentDict-manual_${1}_${2}.err

Queue
EOF
	   )
    else
	_usage "gps1 must be >=gps0"
	exit 1
    fi

###  illegal
else
    _usage
    exit 1
fi

############################################
###  submit or show on sdtout
############################################
if test "${SUBMIT}" = "True"
then
    CMD=condor_submit
else
    CMD=cat
fi

if test ! -e ${EXECUTABLE}
then
    CMD=cat
    msg="${msg}[ \033[31mERROR\033[0m ] ${EXECUTABLE} doesn't exist\n"
fi

if test ! -e ${LOGDIR}
then
    CMD=cat
    msg="${msg}[ \033[31mERROR\033[0m ] ${LOGDIR} doesn't exist\n"
fi

${CMD} <<EOF
${SDF}
EOF
printf "\n${msg}" >&2

############################################
###  EOF
############################################
