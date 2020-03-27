#!/bin/bash

# PLEASE NEVER CHANGE THIS FILE BY HAND.
# This file is generated from condor_jobfile_plotter.sh.
# If you need to change, please edit condor_jobfile_plotter.sh.

echo locksegments
echo $@

if [ $USER == "controls" ]; then
    python /users/DET/tools/GlitchPlot/Script/Kozapy/samples/batch_locksegments.py $@
else
    python /home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples/batch_locksegments.py $@
fi
