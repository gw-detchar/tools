#!/bin/bash
#******************************************#
#     File Name: manualCache.sh
#        Author: Takahiro Yamamoto
# Last Modified: 2020/07/17 20:23:00
#******************************************#


################################
### Helper function
################################
function __error(){
    cat <<EOF > /dev/stderr && exit $1
usage: $0 {L|V} path
  L   : LIGO type cache
  V   : Virgo type cache
  path: Path to gwf file
        This script searches gwf file recursively under '/path/to/gwf'.
EOF
}

################################
### Main
################################
### Arg check
[ "${2}" = "" ] && __error 0
### Virgo (Omicron) format
if test "${1}" = 'V'
then
    #for x in `find ${2} | grep .gwf`
for x in `find ${2} | grep .gwf | sort`
    do
	echo "${x}      `basename $x .gwf | awk -F'-' '{printf(\"%s %s\", $3, $4)}'`  0 0"
    done
### LIGO format
elif test "${1}" = 'L'
then
    for x in `find ${2} | grep .gwf`
    do
	echo "`basename $x .gwf | awk -F'-' '{printf(\"%s %s %s %s\", $1, $2, $3, $4)}'` file://localhost${x}"
    done
else
    __error 1
fi
