#!/bin/bash
#******************************************#
#     File Name: exclude_list.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/24 14:27:41
#******************************************#

DAQINI=/opt/rtcds/kamioka/k1/chans/daq
CONF_DIR=/users/DET/tools/Bruco/share

function execute(){
    [ "${idx}" = "" ] \
	&& REMAINS=`grep -hv '^#' ${DAQINI}/*.ini | grep '_DQ' | sed -e 's/\[K1://g' -e 's/\]//g'` \
	&& PREFIX=`printf "${REMAINS}" | cut -d'-' -f-1 | sort | uniq` \
        || PREFIX=`printf "${REMAINS}" | cut -d'_' -f-${idx} | sort | uniq`
    TMP=`printf "${PREFIX}" | sed -e 's/^/a /g'`
    CANDIDATE=`zenity --list --text="Bruco: exclude list" --checklist --separator=' ' --column=excl. --column=sub-system ${TMP} 2> /dev/null`
    [ $? -eq 1 ] \
	&& exit 0 \
        || (( idx++ ))
    
    OLD="${REMAINS}"
    for x in ${CANDIDATE}
    do
	REMAINS=`printf "${REMAINS}" | grep -v ${x}`
	printf "${x}*\n"
    done
    [ "${REMAINS}" = "${OLD}" ] && exit 0
}  

while :
do
    execute
done

