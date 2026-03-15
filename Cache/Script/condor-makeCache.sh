#!/bin/bash
#set -e
#******************************************#
#     File Name: condor-makeCache.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2026/03/04 03:01:23
#******************************************#

############################################
###  User variables
############################################
MAXJOB=60 ### +/-4
EXECUTABLE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/makeCache.sh
LOGDIR=${HOME}/log
CRON=$(cat <<EOF
      full    */2
      science */2
      second  3-59/10
      minute  5
EOF
    )

############################################
###  Helper functions
############################################
function _usage(){
    cat<<EOF
usage: $0 [-s] [-d] [-CRTM] 0
usage: $0 [-s] [-d] [-CRTM] dir0 [dir1]
usage: $0 [-s] [-d] [-CRTM] gps0 gps1

options:
    -s: submit to condor
    -d: debug-mode
    -C: full frames
    -R: science frames
    -T: second trend frames
    -M: minute trend frames

arguments:
    dir0, dir1: [Int] dir0 <= dir1 <= 99999
    gps0, gps1: [Int] 99999 < gps0 < gps1
${1}
EOF
}

############################################
###  Arguments
############################################
while getopts CRTMsdh OPT; do
    case $OPT in
	s) SUBMIT="True";;
	d) DEBUG="-d";;
	C) FRTYPE="${FRTYPE} full";;
	R) FRTYPE="${FRTYPE} science";;
	T) FRTYPE="${FRTYPE} second";;
	M) FRTYPE="${FRTYPE} minute";;
	h) _usage; exit 0;;
	:) _usage; exit 1;;
	*) _usage; exit 1;;
    esac
done
shift $((OPTIND - 1))

TYPENUM=$(echo "${FRTYPE}" | tr -cd ' ' | wc -c)
if test  ${TYPENUM} -eq 0 -o "${1}" = ""
then
    _usage
    exit 1
fi
let JOBNUM=${MAXJOB}/${TYPENUM}

############################################
###  Submission file
############################################
SDF=$(cat <<EOF
Universe   = vanilla
Notification = never
request_memory = 50MB
Getenv  = True
EOF
      )

###  Online-mode
if test ${1} -eq 0
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

cron_minute    = \$(INTERVAL)
OnExitRemove   = false

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} -c Kashiwa -t \$(FRTYPE) 0
Output     = ${LOGDIR}/makeCache-online_\$(Cluster)_\$(FRTYPE).txt
Error      = ${LOGDIR}/makeCache-online_\$(Cluster)_\$(FRTYPE).err

Queue FRTYPE, INTERVAL from (
EOF
       )
    for frtype in ${FRTYPE}
    do
	SDF=$(cat <<EOF
${SDF}
$(printf "${CRON}" | grep ${frtype})
EOF
	   )
    done
    SDF=$(cat <<EOF
${SDF}
)
EOF
       )

###  directory-mode
elif test ${1} -lt 100000
then
    if test "${2}" = ""
    then
	SDF=$(cat <<EOF
${SDF}

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} -c Kashiwa -t \$(FRTYPE) \$(DIR0)
Output     = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_\$(DIR0).txt
Error      = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_\$(DIR0).err

Queue FRTYPE, DIR0 from (
EOF
	   )
	for frtype in ${FRTYPE}
	do
	    SDF=$(cat <<EOF
${SDF}
      ${frtype} ${1}
EOF
	       )
	done
    elif test ${2} -lt 100000 -a ${1} -le ${2}
    then
	let diff=${2}-${1}
	if test ${diff} -le ${JOBNUM}
	then
	    SDF=$(cat <<EOF
${SDF}

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} -c Kashiwa -t \$(FRTYPE) \$(DIR0)
Output     = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_\$(DIR0).txt
Error      = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_\$(DIR0).err

Queue FRTYPE, DIR0 from (
EOF
	       )
	    for frtype in ${FRTYPE}
	    do
		for dir0 in $(seq ${1} ${2})
		do
		    SDF=$(cat <<EOF
${SDF}
      ${frtype} ${dir0}
EOF
		       )
		done
	    done
	else
	    SDF=$(cat <<EOF
${SDF}

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} -c Kashiwa -t \$(FRTYPE) \$(DIR0) \$(DIR1)
Output     = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_\$(DIR0)_\$(DIR1).txt
Error      = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_\$(DIR0)_\$(DIR1).err

Queue FRTYPE, DIR0, DIR1 from (
EOF
	       )
	    let chunk=(${diff}+${JOBNUM}-1)/${JOBNUM}
	    for frtype in ${FRTYPE}
	    do
		for dir0 in $(seq ${1} ${chunk} ${2})
		do
		    let dir1=${dir0}+${chunk}-1
		    if test ${dir1} -gt ${2}
		    then
			dir1=${2}
		    fi
		    SDF=$(cat <<EOF
${SDF}
      ${frtype} ${dir0} ${dir1}
EOF
		       )
		done
	    done
	fi
    else
	_usage
	exit 1
    fi
    SDF=$(cat <<EOF
${SDF}
)
EOF
       )

###  file-mode
elif test ${1} -ge 100000
then
    if test  "${2}" = ""
    then
	_usage
	exit 1
    elif test ${2} -ge ${1}
    then
	SDF=$(cat <<EOF
${SDF}

Executable = ${EXECUTABLE}
Arguments  = ${DEBUG} -c Kashiwa -t \$(FRTYPE) ${1} ${2}
Output     = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_${1}_${2}.txt
Error      = ${LOGDIR}/makeCache-manual_\$(FRTYPE)_${1}_${2}.err

Queue FRTYPE from (
EOF
	   )
	for frtype in ${FRTYPE}
	do
	    SDF=$(cat <<EOF
${SDF}
      ${frtype}
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
