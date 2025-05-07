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
#+Group         = "Xc"
accounting_group = group_priority

Error        = /home/detchar/log/cache.err
Output       = /home/detchar/log/cache.out

Executable   = /disk/home/detchar/git/kagra-detchar/tools/Cache/Script/makeCache.sh
Arguments    = ${1}

#periodic_remove = (JobStatus == 1) && (time() - QDate) > 45

Queue
EOF

condor_submit tmp.job
rm -f tmp.job
