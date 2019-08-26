#!/bin/bash

# написать свою реализацию ps ax используя анализ /proc

FMT="%-8s%-8s%-5s%-10s%-81s\n"

declare -i NICE
declare -i LOCK
declare -i PID
declare -i SID
declare -i MTHREAD
declare -i FG
declare -i UTIME
declare -i STIME
declare -i TICK
declare -i SEC

printf "$FMT" PID TTY STAT TIME COMMAND

for proc in $(ls /proc/ | egrep "^[0-9]" | sort -n)
do
  if [ -e /proc/$proc/stat ]
  then
  
    # PID 
    PID=$proc
    # Находим TTY
    TTY=$(awk '{print $7}' /proc/$proc/stat)
    
    if [ $TTY -eq 0 ]
    then
      TTY=$(echo \?)
    else    
      TTY=$(ls -la /proc/$proc/fd/ | grep -m 1 'pts\|tty' | awk '{print $11}' | sed 's/\/*dev\///')
        if [ -z $TTY ]
        then
          TTY=$(echo \?)
        fi
    fi    
    
    # Status
    MAIN=$(awk '{print $3}' /proc/$proc/stat)
    
    NICE=$(cat /proc/$proc/stat | awk '{print $19}')
    if [ $NICE -eq 0 ]
    then
        NICE_TEXT=""
    elif [ $NICE -gt 0 ]
    then
        NICE_TEXT="N"
    elif [ $NICE -lt 0 ]
    then
        NICE_TEXT="<"
    fi

    # VmLck из /proc/PID/status, если больше нуля, то ставим L
    LOCK=$(cat /proc/$proc/status | awk '/VmLck/{print $2}')
    if [ $LOCK -gt 0 ]
    then
        LOCK_TEXT="L"
    else
        LOCK_TEXT=""
    fi
    
    # Session Leader. if PID==SID, then s
    PID=$(awk '{print $1}' /proc/$proc/stat)
    SID=$(awk '{print $6}' /proc/$proc/stat)
    if [ $PID -eq $SID ]
    then
        SLID_TEXT="s"
    else
        SLID_TEXT=""
    fi
    
    # Multithread process
    MTHREAD=$(awk '{print $20}' /proc/$proc/stat)
    if [ $MTHREAD -gt 1 ]
    then
        MTHREAD_TEXT="l"
    else
        MTHREAD_TEXT=""
    fi
    
    FG=$(awk '{print $8}' /proc/$proc/stat)
    if [ $FG -eq -1 ]
    then
        FG_TEXT=""
    else
        FG_TEXT="+"
    fi
    
    STAT="$MAIN""$NICE_TEXT""$LOCK_TEXT""$SLID_TEXT""$MTHREAD_TEXT""$FG_TEXT"
    
    # Time
    UTIME=$(awk '{print $14}' /proc/$proc/stat)
    STIME=$(awk '{print $15}' /proc/$proc/stat)
    TICK=$(($UTIME+$STIME))
    SEC=$(($TICK / 100))
    MINUTES=$(($SEC / 60))
    SEC_REST=$(($SEC % 60))
    TIME="$MINUTES:$SEC_REST"
    
    # Command
    COMM=$(tr -d '\0' </proc/$proc/cmdline)
    if [ -z "$COMM" ]
    then
        COMM=$(awk '/Name/{ print $2 }' /proc/$proc/status)
        COMM="[$COMM]"
    else
        COMM=$(echo ${COMM:0:81})
    fi
    
    printf "$FMT" $PID "$TTY" $STAT $TIME "$COMM"
  else
    continue
  fi
done
    
