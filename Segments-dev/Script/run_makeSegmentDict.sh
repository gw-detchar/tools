#!/bin/bash
set -e
#******************************************#
#     File Name: run_makeSegmentDict.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2025/06/18 21:49:33
#******************************************#

### Test on k1det1

if test -e /home/controls/bin/miniconda2/etc/profile.d/conda.sh
then
    source /home/controls/bin/miniconda2/etc/profile.d/conda.sh
elif test -e /kagra/apps/etc/conda3-user-env_deb12.sh
then
    source /kagra/apps/etc/conda3-user-env_deb12.sh
fi

conda activate igwn-py38
python /users/DET/tools/Segments-dev/Script/makeSegmentDict.py $@
conda deactivate

