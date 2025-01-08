#!/bin/bash
#******************************************#
#     File Name: ndscope/ndscope_fast.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2023/08/04 18:48:21
#******************************************#

############################################
###  Environment
############################################
BIN="/usr/bin/ndscope"
MASTER="/opt/rtcds/kamioka/k1/target/fb/master"

############################################
###  Argcheck
############################################
if test "$1" = ""
then
    echo "Usage: $0 [slow] channel1 [channel2 [channel3 ...]]" 
    exit 1
elif test "$1" = "slow"
then
    slow=1
    opt_w="-w 90"
    INCHS=`echo "${@:2}" | tr ' ' '\n' | sort | uniq | tr '\n' ' '`
else
    slow=0
    opt_w="-w 10"
    INCHS=`echo "$@" | tr ' ' '\n' | sort | uniq | tr '\n' ' '`
fi

############################################
###  Argcheck
############################################
CHANS="`grep ini$ ${MASTER} | grep -v '^#'`"
for INCH in ${INCHS}
do
    ### convert SDF list to channel name
    if test "`printf "${INCH}" | grep "_SDF_SP_STAT"`" != ""
    then
    	tmp=`printf "${INCH}" | sed -e 's/_BURT//g' -e 's/_LIVE//g' -e 's/_DIFF//g' -e 's/_TIME//g'`
    	INCH=`caget -S ${tmp} | awk '{print $2}'`
    	caget -S ${INCH} > /dev/null 2>&1
    	ret=$?
    	if test $ret -ne 0
    	then
    	    INCH=`caget -S ${tmp} | awk '{print $2}'`_SWSTAT
    	fi
    fi

    ### convert non-DAQ-ed EPICS to DAQ-ed EPICS (slow)
    OUTCH=`printf ${INCH} \
          | sed -e 's/_OUTMON/_OUTPUT/g' -e 's/_SW1R/_SWSTAT/g' -e 's/_SW2R/_SWSTAT/g' \
	        -e 's/_SW1/_SWSTAT/g' -e 's/_SW2/_SWSTAT/g' -e 's/_Name0[0-9]/_SWSTAT/g' \
		-e 's/_STATE_WORD$/_STATE_WORD_FE/g'`

    if test ${slow} -eq 0
    then
	### convert EPICS to TP
	tmp=${OUTCH}
	OUTCH=`printf ${tmp} \
	      | sed -e 's/_\([IQ]\)_MON$/_\1_ERR/g' \
	            -e 's/_INMON$/_IN1/g' -e 's/_EXCMON$/_EXC/g' \
		    -e 's/_OUT16$/_OUT/g' -e 's/_OUTPUT$/_OUT/g' \
		    -e 's/_WIT_\([LTVRPY]\)MON$/_WIT_\1/g' \
		    -e 's/_LINEMON$/LINE_OUT/g' -e 's/_SLOW$//g' \
		    -e 's/_EPICS_CH/_TP_CH/g'`
	
	### convert DAC_OUTPUT EPICS to TP
	tmp=${OUTCH}
	if test "`printf ${tmp} | grep 'FEC-.*_DAC_OUTPUT_'`" != ""
	then
	    fec=`printf ${tmp} | awk -F'[-_]' '{print $2}'`
	    dac=`printf ${tmp} | awk -F'_' '{print $4}'`
	    ch=`printf ${tmp} | awk -F'_' '{print $5}'`
	    mdl=`grep -l ${tmp} $CHANS | grep -v '^#'`
	    sys=`basename ${mdl} .ini | cut -c 3-5`
	    name=`basename ${mdl} .ini | cut -c 6-`
	    OUTCH="K1:${sys}-${name}_MDAC${dac}_TP_CH${ch}"
	fi

	### convert MON
	tmp=${OUTCH%*_MON}
	if test "`grep -h "${tmp}" ${CHANS} | grep -v '^#'`" != ""
	then
	    OUTCH=${tmp}
	fi

	### convert TP to DQ if exist
	if test "`grep -h ${OUTCH}_DQ ${CHANS} | grep -v '^#'`" != ""
	then
	    OUTCH=${OUTCH}_DQ
	elif test "`grep -h ${OUTCH}_DBL_DQ ${CHANS} | grep -v '^#'`" != ""
	then
	    OUTCH=${OUTCH}_DBL_DQ
	fi
    fi

    ### convert Ramp matrix
    if test "`printf "${OUTCH}" | grep MTRX_RAMPING`" != ""
    then
	tmp=${OUTCH}
	OUTCH="`printf "${tmp}" | sed -e 's/_RAMPING//g'` `printf "${tmp}" | sed -e 's/_RAMPING/_SETTING/g'` ${tmp}"
    fi
    
    OUTCHS="${OUTCHS} ${OUTCH}"
done

${BIN} ${opt_w} ${OUTCHS}
