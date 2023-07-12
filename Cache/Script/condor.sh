#!/bin/bash

[ "${1}" = "" ] && echo "Usage: $0 (The 1st 5 digits of GPS)" && exit 1

cat <<EOF > tmp.job
Universe       = vanilla 
GetEnv         = True
request_memory = 100 MB
#Image_Size     = 8388608
Initialdir     = 
Notify_User    =
Notification   = Never
+Group         = "Xc"

Error        = /dev/null
Log          = /dev/null
Output       = /dev/null

Executable   = /gpfs/home/detchar/git/kagra-detchar/tools/Cache/Script/makeCache.sh
Arguments    = ${1}

periodic_remove = (JobStatus == 1) && (time() - QDate) > 40

Queue
EOF

condor_submit tmp.job
rm -f tmp.job
