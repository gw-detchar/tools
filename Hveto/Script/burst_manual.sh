#!/bin/bash

bursttxt=Burst/EVENTS_LHVK_20191219.txt
#burstxml=Burst/EVENTS_LHVK_20191219.xml
echo "Download burst trigger file."
curl http://157.82.231.182/~ctsweb/ER3_DEC_19_2/M1.R_rMRA_i0cc00_i0rho0_freq16_2048/data/EVENTS.txt > $bursttxt

echo "Download completed."
echo "Convert txt file to xml file."
echo python makeBurstXML.py -f -i $bursttxt 

python makeBurstXML.py -f -i $bursttxt 

echo "Conversion finished."

cat events.txt | while read gpstime
do
    date=`gpstime $gpstime | head -2 | tail -1 | awk '{printf("%s\n", $2)}'`
    # date 2019-12-19
    python GetLockedSegment.py -t $gpstime -d $date > seg.txt
    cat seg.txt | while read gpsstart gpsend
    do
	if [ $gpsstart = "Not" ]; then
	    echo $gpstime "is not observation mode! "
	else
	    echo $gpstime "is observation mode! "
	    /users/DET/tools/Hveto/Script/manual.sh $gpsstart $gpsend $date
	fi
	
    done
done
    
