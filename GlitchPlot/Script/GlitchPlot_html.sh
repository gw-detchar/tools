#!/bin/bash

PATH=$PATH:/home/controls/bin:/home/controls/bin/miniconda2/condabin:/home/controls/.nodenv/bin:/home/controls/opt/summary-2.7/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

echo rsync start.
rsync -a --no-o --copy-links -e "ssh -i ~/.ssh/id_rsa_detchar" chihiro.kozakai@m31-01_ckozakai::kashiwa /mnt/GlitchPlot

echo html generation.
python /users/DET/tools/GlitchPlot/Script/GlitchPlot_html.py

ls /mnt/GlitchPlot/20*/html

echo finish.
