#!/bin/bash

# Usage: ./chlist.sh output_chlist.dat
# $1 is output file name. 
# This file generates channel lists file if $1 does not exist. 
# In condor_jobfile_*.sh, the channel list of this output file $tmp is used line by line. 

source mylib/Kchannels.sh

tmp=$1

if [ ! -e $tmp ]; then
    echo "Make new channel list $1."

    #suffix=(".mean" ".max" ".min")

    # List channels to be plotted in one png file in a line.
    # First line has to be ended by        } > $tmp
    # The other lines have to be ended by  } >> $tmp

#    {
#	echo ${SEIS_IXV[@]} ${LAS_IMC[@]}
#    } > $tmp

    if [ $(echo $2 | grep -e 'IMC-CAV') ]; then
	echo "list for IMC_CAV."
	tmpstr=( ${IMC[@]} ${PEM_IMC[@]} ${SEIS_IXV[@]} ${VIS_IMC[@]})
	{
	    for s in ${tmpstr[@]};do
		echo $s
	    done
	} > $tmp
    elif [ $(echo $2 | grep -e 'PSL-PMC') ]; then
	echo "list for PSL_PMC."
	tmpstr=( ${PSL_PMC[@]} ${PSL_FSS[@]} ${PEM_PSL[@]} ${SEIS_IXV[@]})
	{
	    for s in ${tmpstr[@]};do
		echo $s
	    done
	} > $tmp
    fi	

else
    echo "Use existing list."
fi

#cat $tmp | while read line
#do
#    echo "echo " $line
#done
