#!/bin/bash
#******************************************#
#     File Name: ndscope/gui4medm.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2022/09/13 16:06:57
#******************************************#

################################
### Set variable
################################
NDS2SERVER=k1nds2:8088
#NDSSERVER=157.82.231.173:31200
CMD_ndscope=/usr/bin/ndscope
INI=/opt/rtcds/kamioka/k1/chans/daq/K1EDCU_GRD.ini
GRD="`grep STATE_N ${INI} | tr -d ']' | tr -d '[' | tr '\n' '|'`"

################################
### Set variable
################################
def_gpsend=`gpstime | grep GPS | awk '{printf("%d\n", $2-64)}'`
def_dateend=`gpstime ${def_gpsend} -u -f "%Y-%m-%d"`
def_timeend=`gpstime ${def_gpsend} -u -f "%H:%M:%S"`
def_duration=86400
def_unit=seconds
echo "${GRD}"
################################
### GUI interface
################################
flag=0
while test ${flag} -eq 0
do
    ZEN_OUT=`zenity --forms --text="ndscope${msg}" --separator=',' --add-entry="gps end (${def_gpsend})" --add-entry="date (${def_dateend})" --add-entry="time (${def_timeend})" --add-entry="duration (${def_duration})" --add-combo="unit (${def_unit})" --combo-values='seconds|minutes|hours|days' --add-combo="grd state (NONE)" --combo-values="${GRD}" 2> /dev/null`
    [ $? -eq 1 ] && exit 1
    
    gpsend=`printf "${ZEN_OUT}" | cut -d',' -f1`
    [ "${gpsend}" = "" ] && gpsend=${def_gpsend} || def_gpsend=${gpsend}
    printf "gpsend: ${gpsend}\n" >&2 
    
    dateend=`printf "${ZEN_OUT}" | cut -d',' -f2`
    [ "${dateend}" = "" ] && dateend=${def_dateend} #|| def_dateend=${dateend}
    printf "gpsend: ${dateend}\n" >&2 
    
    timeend=`printf "${ZEN_OUT}" | cut -d',' -f3`
    [ "${timeend}" = "" ] && timeend=${def_timeend} #|| def_timeend=${timeend}
    printf "gpsend: ${timeend}\n" >&2 
    
    duration=`printf "${ZEN_OUT}" | cut -d',' -f4`
    [ "${duration}" = "" ] && duration=${def_duration} || def_duration=${duration}
    printf "duration: ${duration}\n" >&2

    unit=`printf "${ZEN_OUT}" | cut -d',' -f5`
    [ "${unit}" = "" ] && unit=${def_unit} || def_unit=${unit}
    printf "unit: ${unit}\n" >&2

    grd=`printf "${ZEN_OUT}" | cut -d',' -f6`
    printf "grd: ${grd}\n" >&2

    if test ${dateend} != ${def_dateend} -o ${timeend} != ${def_timeend}
    then
	gpsend=`gpstime "${dateend} ${timeend} UTC" | grep GPS | awk '{printf("%d\n", $2-64)}'`
	printf "gpsend: ${gpsend}\n" >&2
    fi

    case "${unit}" in
	"seconds") duration=${duration};;
	"minutes") let duration=${duration}*60;;
	"hours") let duration=${duration}*3600;;
	"days") let duration=${duration}*86400;;
    esac

    let gpsepoch=${gpsend}-${duration}/2
    flag=1
done # end of while test flag

CHANS="`echo $@ | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/SW1R/SWSTAT/g' -e 's/SW2R/SWSTAT/g' -e 's/_OUTMON/_OUT16/g'`"
${CMD_ndscope} --nds ${NDS2SERVER} -t ${gpsepoch} -w ${duration} ${CHANS} ${grd}

