#!/bin/bash
#condor_submit /home/detchar/git/kagra-detchar/tools/Segments/Script/kashiwa_fine.sdf 

#PATH=/home/controls/bin:/usr/bin:/home/controls/opt/virgosoft/UPV/v2r3/Linux-x86_64:/home/controls/opt/virgosoft/VetoPerf/v2r3/Linux-x86_64:/home/controls/opt/virgosoft/Omicron/v2r3/Linux-x86_64:/home/controls/opt/virgosoft/Omicron/v2r3/scripts:/home/controls/opt/virgosoft/GWOLLUM/v2r3/Linux-x86_64:/home/controls/opt/virgosoft/ligotools/v2r59/scripts:/home/controls/opt/virgosoft/Fr/v8r32p1/Linux-x86_64:/home/controls/opt/virgosoft/HDF5/v1r10p1/Linux-x86_64/bin:/home/controls/opt/virgosoft/root/v6r14p040//bin:/home/controls/opt/summary-2.7/bin:/usr/local/bin:/bin:/usr/local/games:/usr/games:/home/controls/opt/summary-2.7/bin/:/home/controls/opt/virgosoft/CMT/v1r26p20160527/Linux-x86_64:/home/controls/opt/virgosoft/Gsl/v1r16p2/Linux-x86_64/bin

#python /users/DET/tools/Segments/Script/make15minSegment.py

#
# this script will launch at k1det1
#
source /home/controls/bin/miniconda2/etc/profile.d/conda.sh
#source /home/controls/miniconda3/etc/profile.d/conda.sh
conda activate igwn-py38

#python /users/DET/tools/Segments/Script/make15minSegment_igwn.py -c Kamioka -o /users/DET/tools/Segments/Script/tmp
#python /users/DET/tools/Segments/Script/make15minSegment_igwn.py -c Kamioka -o /users/DET/Segments
python /users/DET/tools/Segments/Script/make15minSegment_igwn.py -c Kamioka -o /users/DET/tools/Segments/Script/Partial
