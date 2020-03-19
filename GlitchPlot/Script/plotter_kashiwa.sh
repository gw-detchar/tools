#!/bin/bash

# input trigger file
#inputtriggerfile="K1-IMC_CAV_ERR_OUT_DQ_OMICRON-1241900058-60.xml.gz"
#inputtriggerfile="K1-IMC_CAV_REFL_OUT_DQ_OMICRON-1242713238-60.xml.gz"
# output parameter txt file
#parameterlist="parameter.txt"

# Get time to process. The time is when omicron output is made.
# Use the last quarter hour.
#

cd /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script


# Please replace the - to _.
#channels=("LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ" "IMC_SERVO_SLOW_DAQ_OUT_DQ" "AOS_TMSX_IR_PD_OUT_DQ" "IMC_CAV_TRANS_OUT_DQ" "PSL_PMC_TRANS_DC_OUT_DQ")
#channels=("IMC_CAV_TRANS_OUT_DQ" "PSL_PMC_TRANS_DC_OUT_DQ" "PEM_ACC_MCF_TABLE_REFL_Z_OUT_DQ" "PEM_ACC_PSL_PERI_PSL1_Y_OUT_DQ" "PEM_MIC_PSL_TABLE_PSL4_Z_OUT_DQ")
#snr > 10
#channels=("LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ" "AOS_TMSX_IR_PD_OUT_DQ" "IMC_CAV_TRANS_OUT_DQ" "IMC_CAV_REFL_OUT_DQ" "PSL_PMC_MIXER_MON_OUT_DQ")
#snr>20
#channels=("IMC_MCL_SERVO_OUT_DQ" "PSL_PMC_TRANS_DC_OUT_DQ")
#snr>7
#channels=("IMC_SERVO_SLOW_DAQ_OUT_DQ")
channels=("CAL_CS_PROC_DARM_DISPLACEMENT_DQ")

list=()

for channel in ${channels[@]};do
#list+=( `find /home/detchar/triggers/K1/${channel}_OMICRON/126*/` )
list+=( `find /home/detchar/triggers/K1/${channel}_OMICRON/1266*/` )

for file in ${list[@]};do
    
    if [ -d $file ]; then
	continue
    fi
	
    echo $file
    
    echo "---------trigger file reading---------"
    # process the trigger data and determine plot parameter
    parameterlist="/home/chihiro.kozakai/detchar/ER/parameter/"`basename $file`".txt"
    python plotter.py -i $file -o $parameterlist -k  
    echo  $parameterlist
    echo "----------plot job throwing----------"
    # from the plot parameter, throw condor job to make basic plots.
    ./condor_jobfile_plotter.sh $parameterlist

done

done
echo "Finished."

