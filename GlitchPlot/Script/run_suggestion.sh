#!/bin/bash

# PLEASE NEVER CHANGE THIS FILE BY HAND.
# This file is generated from successcheck_17269.sh.
# If you need to change, please edit successcheck_17269.sh.

echo suggestion
echo $@

if [ $USER == "controls" ]; then
    python /users/DET/tools/GlitchPlot/Script/suggestion.py $@
else
    python /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/suggestion.py $@
fi
