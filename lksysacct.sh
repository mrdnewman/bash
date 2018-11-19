#!/usr/bin/env bash


    # -- Lock down system accounts ...
    # -- lksysacct.sh
    # --
    # --


SCRIPT_NAME=`basename $0`;


for user in `awk -F: '($3 < 500) {print $1 }' /etc/passwd`; do

   if [ $user != "root" ]; then
      /usr/sbin/usermod -L $user

   if [ $user != "sync" ] && [ $user != "shutdown" ] && [ $user != "halt" ]; then
      /usr/sbin/usermod -s /sbin/nologin $user

   fi
   fi

done
