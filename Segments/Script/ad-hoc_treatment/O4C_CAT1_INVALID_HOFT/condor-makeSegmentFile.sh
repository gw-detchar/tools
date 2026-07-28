#!/bin/bash
#set -e
#******************************************#
#     File Name: condor-makeSegmentFile.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2026/07/28 15:09:45
#******************************************#

############################################
###  User variables
############################################
EXECUTABLE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/makeSegmentFile.py
LOGDIR=${HOME}/log

############################################
###  Helper functions
############################################
function _usage(){
    cat<<EOF
usage: $0 [-s] -p output_directory

options:
    -s: submit to condor

${1}
EOF
}

############################################
###  Arguments
############################################
while getopts p:s OPT; do
    case $OPT in
	p) DIR=${OPTARG};;
	s) SUBMIT="True";;
	h) _usage; exit 0;;
	:) _usage; exit 1;;
	*) _usage; exit 1;;
    esac
done
shift $((OPTIND - 1))

if test  "${DIR}" = ""
then
    _usage
    exit 1
fi

############################################
###  Submission file
############################################
SDF=$(cat <<EOF
Universe   = vanilla
Notification = never
request_memory = 100KB
Getenv  = True
EOF
      )

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

Executable = ${EXECUTABLE}
Arguments  = --path ${DIR}
Output     = ${LOGDIR}/makeSegmentFile_O4C_INVALID_HOFT_\$(Cluster).txt
Error      = ${LOGDIR}/makeSegmentFile_O4C_INVALID_HOFT_\$(Cluster).err

Queue
EOF
   )

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
