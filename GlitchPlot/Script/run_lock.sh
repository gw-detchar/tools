#!/bin/bash

# PLEASE NEVER CHANGE THIS FILE BY HAND.
# This file is generated from successcheck.sh.
# If you need to change, please edit successcheck.sh.

echo lock
echo $@
python /home/chihiro.kozakai/detchar/analysis/code/gwpy/Kozapy/samples/batch_locksegment.py $@
