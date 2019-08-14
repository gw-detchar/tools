#!/bin/bash

# input trigger file
#inputtriggerfile="K1-IMC_CAV_ERR_OUT_DQ_OMICRON-1241900058-60.xml.gz"
#inputtriggerfile="K1-IMC_CAV_REFL_OUT_DQ_OMICRON-1242713238-60.xml.gz"
# output parameter txt file
#parameterlist="parameter.txt"

# Get time to process. The time is when omicron output is made.
# Use the last quarter hour.
#

cd /users/DET/tools/GlitchPlot/Script

INTERVAL=15

#let mm=`date +"%M"`/${INTERVAL}*${INTERVAL}
let mm=`date +"%M" | sed -e "s/^0//"`/${INTERVAL}*${INTERVAL}


jst_end="`date +"%Y-%m-%d %H:${mm}:00"`"

[ -e /usr/bin/gpstime ] && cmd_gps=/usr/bin/gpstime || cmd_gps=/home/controls/bin/gpstime

GPS_END=`${cmd_gps} ${jst_end}| head -3 | tail -1 | awk '{printf("%d\n", $2)}'`

let GPS_START=${GPS_END}-${INTERVAL}*60

jst_start=`${cmd_gps} ${GPS_START}| head -1`
jst_start=${jst_start#*:}

let GPS_START=${GPS_END}-${INTERVAL}*60

echo $jst_start
echo $jst_end
echo $GPS_START
echo $GPS_END


let tmp=${GPS_END:0:5}-1
#echo $tmp

# Please replace the - to _.
#X-arm
#channels=("LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ" "IMC_SERVO_SLOW_DAQ_OUT_DQ" "AOS_TMSX_IR_PD_OUT_DQ" "IMC_CAV_TRANS_OUT_DQ" "PSL_PMC_TRANS_DC_OUT_DQ" "CAL_CS_PROC_XARM_FREQUENCY_DQ")
channels=("CAL_CS_PROC_XARM_FREQUENCY_DQ")
#IMC
#channels=("IMC_CAV_TRANS_OUT_DQ" "PSL_PMC_TRANS_DC_OUT_DQ" "PEM_ACC_MCF_TABLE_REFL_Z_OUT_DQ" "PEM_ACC_PSL_PERI_PSL1_Y_OUT_DQ" "PEM_MIC_PSL_TABLE_PSL4_Z_OUT_DQ")
#MICH
#channels=("IMC_CAV_TRANS_OUT_DQ" "PSL_PMC_TRANS_DC_OUT_DQ" "LSC_REFL_PDA1_RF17_Q_ERR_DQ" "LSC_POP_PDA1_RF17_Q_ERR_DQ"  "LSC_AS_PDA1_RF17_Q_ERR_DQ" "CAL_CS_PROC_IMC_FREQUENCY_DQ")

list=()

for channel in ${channels[@]}; do
    list+=( `find /home/controls/triggers/K1/${channel}_OMICRON/${GPS_END:0:5}/ -newermt "$jst_start" -and ! -newermt "$jst_end"` `find /home/controls/triggers/K1/${channel}_OMICRON/${tmp}/ -newermt "$jst_start" -and ! -newermt "$jst_end"` )



    for file in ${list[@]};do
	
	if [ -d $file ]; then
	    continue
	fi
	
	echo $file
	
	echo "---------trigger file reading---------"
	# process the trigger data and determine plot parameter
	today="`date +%Y%m%d`"
	if [ ! -e /users/DET/Result/GlitchPlot/parameter/$today/ ]; then
	    mkdir -p /users/DET/Result/GlitchPlot/parameter/$today/
	fi
	
	parameterlist="/users/DET/Result/GlitchPlot/parameter/$today/"`basename $file`".txt"
	python plotter.py -i $file -o $parameterlist 
	echo  $parameterlist
#	echo "----------plot job throwing----------"
	# from the plot parameter, throw condor job to make basic plots.
	#./condor_jobfile_plotter.sh $parameterlist

    done

done

# scp produced files.

let hh=`date +"%H"`-1
jst_end="`date +"%Y-%m-%d ${hh}:${mm}:00"`"

GPS_END=`${cmd_gps} ${jst_end}| head -3 | tail -1 | awk '{printf("%d\n", $2)}'`

let GPS_START=${GPS_END}-${INTERVAL}*60

jst_start=`${cmd_gps} ${GPS_START}| head -1`
jst_start=${jst_start#*:}

#list=( `find /users/DET/Result/GlitchPlot/plotter_K1* -newermt "$jst_start" -and ! -newermt "$jst_end" -type d`  )
#list=( `find /users/DET/Result/GlitchPlot/20*/plotter_* -newermt "$jst_start" -and ! -newermt "$jst_end" -type d`  )

#for file in ${list[@]};do
#    echo "scp directory " $file
#    scp -i ~/.ssh/id_rsa_icrhome_ckozakai -r $file ckozakai@icrhome05.icrr.u-t#okyo.ac.jp:

#done

#rsync /users/DET/Result/GlitchPlot/ ckozakai@icrhome05.icrr.u-tokyo.ac.jp:
#rsync -avz -e "ssh -v -i ~/.ssh/id_rsa_icrhome_ckozakai" --exclude="parameter/*.txt" /users/DET/Result/GlitchPlot/ ckozakai@icrhome05.icrr.u-tokyo.ac.jp:public_html/KAGRA/GlitchPlot/

rsync -avz -e "ssh -v -i ~/.ssh/id_rsa_icrhome_ckozakai"  /users/DET/Result/GlitchPlot/parameter chihiro.kozakai@m31-01_ckozakai:public_html/KAGRA/GlitchPlot/parameter/

