#!/bin/bash
#******************************************#
#     File Name: makeCache.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/01/20 23:25:11
#******************************************#


################################
### Set enviroment
################################
[ -e /kagra/apps/etc/client-user-env.sh ] && source  /kagra/apps/etc/client-user-env.sh
if test `whoami` = "controls"
then
    DIR_FR0=/frame0/full
    DIR_FR1=/frame1/full
    DIR_CACHE=/users/DET/Cache
    FILE_CACHE=${DIR_CACHE}/latest
    [ -e /usr/bin/gpstime ] && CMD_GPS=/usr/bin/gpstime || CMD_GPS=/kagra/apps/cdsutils/bin/gpstime
else
    DIR_FR0=/data/full
    DIR_FR1=/data/full
    DIR_CACHE=${HOME}/cache
    FILE_CACHE=${DIR_CACHE}/latest
    CMD_GPS=${HOME}/bin/gpstime
fi

################################
### Usage
################################
[ "${1}" = "" ] && cat <<EOF > /dev/stderr && exit 0
usage: $0 directory
       directory: upper five digits of the GPS tiem
                  When directory is 0, current time is used.
EOF


################################
### remove old caches
################################
for x in `ls ${DIR_CACHE}/Cache_GPS/*.ffl 2> /dev/null`
do
    GPS5=`basename $x .ffl`
    if test ! -e ${DIR_FR0}/${GPS5}
    then
	echo "rm -f ${DIR_CACHE}/Cache_GPS/${GPS5}.*" > /dev/stderr
	rm -f ${DIR_CACHE}/Cache_GPS/${GPS5}.*
    fi
done
    

################################
### arg check
################################
if test "${1}" = "0"
then
    FILE_LATEST=`ls ${DIR_CACHE}/Cache_GPS/*.ffl | sort -r | head -1`
    GWF_LATEST=`tail -1 ${FILE_LATEST}`
    GPS_LATEST=`printf "${GWF_LATEST}" | awk '{print $2}'`
    LEN_LATEST=`printf "${GWF_LATEST}" | awk '{print $3}'`
    GPS_STOP=`${CMD_GPS} | head -3 | tail -1 | sed -e 's/ GPS/GPS/g' | awk -F'[ .]' '{print $2}'`
    let GPS_LATEST=${GPS_LATEST}+${LEN_LATEST}
else
    GPS_LATEST=${1}00000
    let GPS_STOP=${GPS_LATEST}+100000
    LEN_LATEST=`ls ${DIR_FR0}/${1}/*.gwf 2> /dev/null | head -1 | cut -d'-' -f4 | sed -e 's/.gwf//g'`
    if test "${FILE_TMP}" = ""
    then
	LEN_LATEST=`ls ${DIR_FR1}/${1}/*.gwf 2> /dev/null | head -1 | cut -d'-' -f4 | sed -e 's/.gwf//g'`
	[ "${LEN_LATEST}" = "" ] && echo "Can't find both ${DIR_FR0}/${1}/ and ${DIR_FR1}/${1}/." > /dev/stderr && exit 1
    fi
    printf "" > ${DIR_CACHE}/Cache_GPS/${1}.ffl
fi
cat <<EOF > /dev/stderr
#####################
#  START: ${GPS_LATEST}
#    END: ${GPS_STOP}
# LENGTH: ${LEN_LATEST}
#####################
EOF


################################
### search latest cache
################################
while test ${GPS_LATEST} -lt ${GPS_STOP}
do
    let GPS5_LATEST=${GPS_LATEST}/100000
    GWF0_LATEST="`ls ${DIR_FR0}/${GPS5_LATEST}/*-${GPS_LATEST}-${LEN_LATEST}.gwf 2> /dev/null`"
    if test "${GWF0_LATEST}" != ""
    then
	LEN_LATEST=`printf "${GWF0_LATEST}" | cut -d'-' -f4 | sed -e 's/.gwf//g'`
	printf "${GWF0_LATEST}\t${GPS_LATEST} ${LEN_LATEST}  0 0\n" >> ${DIR_CACHE}/Cache_GPS/${GPS5_LATEST}.ffl
    else
	GWF1_LATEST="`ls ${DIR_FR1}/${GPS5_LATEST}/*-${GPS_LATEST}-${LEN_LATEST}.gwf 2> /dev/null`"
	if test "${GWF1_LATEST}" != ""
	then
	    LEN_LATEST=`printf "${GWF1_LATEST}" | cut -d'-' -f4 | sed -e 's/.gwf//g'`
	    printf "${GWF1_LATEST}\t${GPS_LATEST} ${LEN_LATEST}  0 0\n" >> ${DIR_CACHE}/Cache_GPS/${GPS5_LATEST}.ffl
	fi
    fi
    let GPS_LATEST=${GPS_LATEST}+${LEN_LATEST}
done


for x in `ls ${DIR_CACHE}/Cache_GPS/*.ffl 2> /dev/null`
do
    y=${DIR_CACHE}/Cache_GPS/`basename $x .ffl`.cache
    if test ! -e $y -o $x -nt $y
    then
	cat ${x} | awk '{printf("K K1_C %ld %d file://localhost%s\n", $2, $3, $1)}' > ${y}
    fi
done


################################
### merge caches
################################
if test `whoami` = "controls"
then
    cat ${DIR_CACHE}/Cache_GPS/*.ffl > ${FILE_CACHE}.ffl
    cat ${DIR_CACHE}/Cache_GPS/*.cache > ${FILE_CACHE}.cache
else
    cat `ls ${DIR_CACHE}/Cache_GPS/*.ffl | tail -7` > ${FILE_CACHE}.ffl
    cat `ls ${DIR_CACHE}/Cache_GPS/*.cache | tail -7` > ${FILE_CACHE}.cache
fi
