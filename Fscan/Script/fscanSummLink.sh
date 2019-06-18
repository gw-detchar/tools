#!/bin/bash
#******************************************#
#     File Name: Fscan/fscanSummLink.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2019/04/09 21:36:33
#******************************************#

orig_root=/mnt/fscan/daily
dest_root=/mnt/fscan/summ

target=`date +"fscans_%Y_%m_%d_09_00_00_JST_%a"`
link=`date --date='1 day ago' +"fscans_%Y_%m_%d_09_00_00_JST"`

mkdir -p ${dest_root}
ln -s ${orig_root}/${target} ${dest_root}/${link}

