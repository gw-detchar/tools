#!/bin/bash

for i in `seq 14040 14064`
do
    #echo $i
    fname=/home/detchar/cache/Cache_GPS/${i}.ffl

    n=`cat $fname | sort | uniq -d | wc -l`
    echo "${fname}: ${n}"
    
done
