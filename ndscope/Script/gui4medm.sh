#!/bin/bash
#******************************************#
#     File Name: ndscope/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/27 17:47:59
#******************************************#

################################
### Set variable
################################
CMD_ndscope=/usr/bin/ndscope

################################
### Set variable
################################
def_gpsend=`gpstime | grep GPS | awk '{printf("%d\n", $2-64)}'`
def_duration=86400
def_unit=seconds

################################
### GUI interface
################################
flag=0
while test ${flag} -eq 0
do
    ZEN_OUT=`zenity --forms --text="ndscope${msg}" --separator=',' --add-entry="gps end (${def_gpsend})" --add-entry="duration (${def_duration})" --add-combo="unit (${def_unit})" --combo-values='seconds|minutes|hours|days' 2> /dev/null`
    [ $? -eq 1 ] && exit 1
    
    gpsend=`printf "${ZEN_OUT}" | cut -d',' -f1`
    [ "${gpsend}" = "" ] && gpsend=${def_gpsend} || def_gpsend=${gpsend}
    printf "gpsend: ${gpsend}\n" >&2 
    
    duration=`printf "${ZEN_OUT}" | cut -d',' -f2`
    [ "${duration}" = "" ] && duration=${def_duration} || def_duration=${duration}
    printf "duration: ${duration}\n" >&2

    unit=`printf "${ZEN_OUT}" | cut -d',' -f3`
    [ "${unit}" = "" ] && unit=${def_unit} || def_unit=${unit}
    printf "unit: ${unit}\n" >&2

    case "${unit}" in
	"seconds") duration=${duration};;
	"minutes") let duration=${duration}*60;;
	"hours") let duration=${duration}*3600;;
	"days") let duration=${duration}*86400;;
    esac

    let gpsepoch=${gpsend}-${duration}/2
    flag=1
done # end of while test flag


${CMD_ndscope} -t ${gpsepoch} -w ${duration} $1
