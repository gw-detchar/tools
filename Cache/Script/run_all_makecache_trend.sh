#!/bin/bash

submit=tmp.job

rm -f $submit

cat <<EOF > $submit
Universe       = vanilla 
GetEnv         = True
request_memory = 100 MB
Initialdir     = 
Notify_User    =
Notification   = Never
#accounting_group = group_priority

Error        = /home/detchar/log/cache_regenerate_trend.err
Output       = /home/detchar/log/cache_regenerate_trend.out

EOF

#for i in `seq 11723 14306`
for i in `seq 13001 14306`
do

    echo $i
    #echo "/home/detchar/cache/CacheSecond_GPS/${i}.ffl"
    echo "/data/KAGRA/raw/full/${i}"

    flag=0
    
    if [ ! -d /data/KAGRA/raw/trend/second/${i} ]; then
	echo "*** no directory"
	flag=1
    fi
   
    [[ $flag == 0 ]] && {

	# directory=/data/KAGRA/raw/full/${i}
	# if [ -n "$(ls $directory)" ]; then
	#     echo "*** no frame files"
	#     flag=1 
	# fi
	
	#rm /home/detchar/cache/CacheSecond_GPS/${i}.ffl
	#rm /home/detchar/cache/CacheSecond_GPS/${i}.cache
	#./makeCache.sh $i
	#./makeCache_SecondTrend.sh $i
	#./makeCache_MinuteTrend.sh $i

	echo "Executable   = /disk/home/detchar/git/kagra-detchar/tools/Cache/Script/makeCache_MinuteTrend.sh" >> $submit
	echo "Arguments    = ${i}" >> $submit
	echo "Queue" >> $submit
	
	echo "Executable   = /disk/home/detchar/git/kagra-detchar/tools/Cache/Script/makeCache_SecondTrend.sh" >> $submit
	echo "Arguments    = ${i}" >> $submit
	echo "Queue" >> $submit
	
    }
done

condor_submit $submit
rm -f $submit
