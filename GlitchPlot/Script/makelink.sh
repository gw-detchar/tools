#!/bin/bash

#date="`date +%Y%m%d`"
date=$1

mkdir -p /home/chihiro.kozakai/public_html/KAGRA/toKamioka/GlitchPlot/${date}/events

list=( `ls /home/chihiro.kozakai/public_html/KAGRA/GlitchPlot/${date}/* -d` )

for directory in ${list[@]}; do
    ln -s ${directory} /home/chihiro.kozakai/public_html/KAGRA/toKamioka/GlitchPlot/${date}/events/
done
