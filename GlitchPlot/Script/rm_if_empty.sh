#!/bin/bash
for file in "$@"; do
  if [ -f $file  -a ! -s $file ];then
      rm -f $file
  fi
done
