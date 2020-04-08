#!/bin/bash

# Assumes it runs on k1det0.

date="`date +%Y%m%d`"
#date=20200407

mkdir -p /mnt/GlitchPlot/${date}/events

scp -r -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa_detchar chihiro.kozakai@m31-01_ckozakai:public_html/KAGRA/GlitchPlot/${date}/* /mnt/GlitchPlot/${date}/events/
