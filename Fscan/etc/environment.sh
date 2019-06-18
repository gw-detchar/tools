if test `whoami` = "controls"
then
    export KAGRA_FSCANBIN_PATH=/users/DET/tools/Fscan/Script
else
    export KAGRA_FSCANBIN_PATH=${HOME}/opt/Fscan
fi
export MAKESFTS_PATH=/usr/bin
export SPECAVG_PATH=/usr/bin
export PLOTSPECAVGOUTPUT_PATH=/home/controls/opt/Fscan
