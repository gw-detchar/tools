#!/bin/bash

echo rsync start.
rsync -a --no-o --copy-links -e "ssh -i ~/.ssh/id_rsa_detchar" chihiro.kozakai@m31-01_ckozakai::kashiwa /mnt/GlitchPlot

echo html generation.
python /users/DET/tools/GlitchPlot/Script/GlitchPlot_html.py

echo finish.
