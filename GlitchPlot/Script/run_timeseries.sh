#!/bin/bash

# PLEASE NEVER CHANGE THIS FILE BY HAND.
# This file is generated from successcheck_17269.sh.
# If you need to change, please edit successcheck_17269.sh.

echo timeseries
echo $@

if [ $USER == "controls" ]; then
    python /users/DET/tools/GlitchPlot/Script/Kozapy/samples/batch_timeseries.py $@
else
    python /home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples/batch_timeseries.py $@
fi
