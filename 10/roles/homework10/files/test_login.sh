#!/bin/bash
if [ $PAM_USER = "root" ];then
  exit 0
fi
IS_WHEEL=$(groups $PAM_USER | awk -F : '{print $2}'| grep '\<wheel\>')
if [ -z "$IS_WHEEL" ]; then
    if [[ $(date +%a) = "Sat" || $(date +%a) = "Sun" ]]; then
       exit 1
    else
       exit 0
    fi
else
   exit 0
fi

