#!/bin/bash
#******************************************#
#     File Name: replace_segment_name.sh
#        Author: Hirotaka Yuzurihara
# Last Modified: 2025/01/09
#******************************************#

##############################
# Edit following variables
##############################
dirin="/users/yuzu/Segments"
dirout="/users/yuzu/Segments_new"
old="K1-DAQ-IPC_ERROR"
new="K1-DAQ_IPC_ERROR"
##############################

old_no_k1=`echo ${old} | cut -c4-`
new_no_k1=`echo ${new} | cut -c4-`

for year in 2023 2024 2025
do

    mkdir -p ${dirout}/${new}/${year}
    
    for ii in `ls ${dirin}/${old}/${year}/*`
    do
	old_file=`basename $ii`
	tail=`echo $old_file | awk -F "$old" '{print $2}'`
	new_file="${dirout}/${new}/${year}/${new}${tail}"
	echo $ii
	echo $tail
	echo $new_file

	cat $ii | sed -e "s/${old_no_k1}/${new_no_k1}/g" > ${new_file}

	echo ""
	
    done
done
