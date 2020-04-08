#!/bin/bash

date=$1

if [ "${date}" == "" ]; then
    date="`date +%Y%m%d`"
fi

mkdir -p /home/chihiro.kozakai/public_html/KAGRA/toKamioka/GlitchPlot/${date}/events

list=( `ls /home/chihiro.kozakai/public_html/KAGRA/GlitchPlot/${date}/* -d` )

for directory in ${list[@]}; do

    basedir=`basename ${directory}`

    if [ ! -e /home/chihiro.kozakai/public_html/KAGRA/toKamioka/GlitchPlot/${date}/events/${basedir} ]; then
	ln -s ${directory} /home/chihiro.kozakai/public_html/KAGRA/toKamioka/GlitchPlot/${date}/events/
    fi
done
