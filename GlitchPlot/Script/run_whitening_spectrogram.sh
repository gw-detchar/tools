#!/bin/bash

# PLEASE NEVER CHANGE THIS FILE BY HAND.
# This file is generated from successcheck_1722.sh.
# If you need to change, please edit successcheck_1722.sh.

echo whitening_spectrogram
echo $@
python /home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples/batch_whitening_spectrogram.py $@
