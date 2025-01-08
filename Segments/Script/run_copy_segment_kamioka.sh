#!/bin/bash
#******************************************#
#     File Name: run_copy_segment_kamioka.sh
#        Author: Hirotaka Yuzurihara
# Last Modified: 2024/07/22
#******************************************#


### This script will launch at k1det1 by crontab
### This script will copy the segment file for the latest 24 hours. The partial segment will not be copied.
yesterday=`date --date 'yesterday' +"%Y-%m-%d"` # ex) 2024-07-23
year=`date --date 'yesterday' +"%Y"` # ex) 2024-07-23
echo $yesterday $year

for ii in `ls /users/DET/tools/Segments/Script/Partial/`
do
    segment=`basename $ii`
    if [ ! -d /users/DET/Segments/${segment}/${year} ]; then
	mkdir /users/DET/Segments/${segment}/${year}
    fi
    cp -r /users/DET/tools/Segments/Script/Partial/${segment}/${year}/*${yesterday}* /users/DET/Segments/${segment}/${year}/

    #cp -r /users/DET/tools/Segments/Script/Partial/${segment}/${year}/* /users/DET/Segments/${segment}/${year}/
done

