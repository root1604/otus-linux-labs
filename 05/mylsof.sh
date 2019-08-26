#!/bin/bash

# написать свою реализацию lsof используя анализ /proc

FMT="%-16s%-8s%-8s%-10s%-10s%-10s%-10s%-10s%-10s%-73s\n"

printf "$FMT" COMMAND PID TID USER FD TYPE DEVICE SIZE/OFF NODE NAME 

for proc in $(ls /proc/ | egrep "^[0-9]" | sort -n)
do
  if [ -e /proc/$proc/stat ]
  then
    #USER
    USER=$(ls -ld /proc/$proc/ | awk '{print $3}')
  
    #COMMAND
    COMMAND=$(awk '{print $2}' /proc/$proc/stat | sed 's/[()]//g')
    
    #PID 
    PID=$proc
    
    #TID
    TID=""
    
    #cwd
    FD="cwd"
    NAME=$(ls -l /proc/$proc/ 2>/dev/null| grep 'cwd -> '| awk '{print $11}')
    TYPE="DIR"
    DEVICE="253,0"
    SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
    INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
    printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
    
    #rtd
    FD="rtd"
    NAME=$(ls -l /proc/$proc/ 2>/dev/null| grep 'root -> '| awk '{print $11}')
    TYPE="DIR"
    DEVICE="253,0"
    SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
    INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
    printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
    
    #txt
    FD="txt"
    NAME=$(ls -l /proc/$proc/ 2>/dev/null| grep 'exe -> '| awk '{print $11}')
    if [ -z $NAME ]
    then
    NAME="/proc/$proc/exe"
    TYPE="unknown"
    DEVICE=""
    SIZE=""
    INODE=""
    else
    TYPE="REG"
    DEVICE="253,0"
    SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
    INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
    fi
    printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
    
    #mem
    FD="mem"
    TYPE="REG"
    DEVICE="253,0"
    IFS=$'\n'
    for maps_line in $(cat /proc/$proc/maps | awk '{print $6}' | sed '/^$/d' | sed '1,/\[/d' | sed '/\[/d' | awk '! a[$0]++')
    do
      NAME="$maps_line"
      SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
      INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
      printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
    done
    
    IFS=$'\n'
    for line in $(ls -l /proc/$proc/fd | grep -v '^total' | sort -k9 -n)  
    do
      #NAME
      NAME=$(echo $line 2>/dev/null| awk '{print $11}')
      FD=$(echo $line 2>/dev/null| awk '{print $9}')
      TYPE=""
      DEVICE=""
      SIZE=""
      INODE=""
      printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
        
    done  
    
    for thread in $(ls /proc/$proc/task/ 2>/dev/null| egrep "^[0-9]" | sort -n)
    do
      if [ $thread -ne $PID ]
      then
        TID=$thread
        
        #cwd
        FD="cwd"
        NAME=$(ls -l /proc/$proc/task/$thread/ 2>/dev/null| grep 'cwd -> '| awk '{print $11}')
        TYPE="DIR"
        DEVICE="253,0"
        SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
        INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
        printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
        
        #rtd
        FD="rtd"
        NAME=$(ls -l /proc/$proc/task/$thread/ 2>/dev/null| grep 'root -> '| awk '{print $11}')
        TYPE="DIR"
        DEVICE="253,0"
        SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
        INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
        printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
        
        #txt
        FD="txt"
        NAME=$(ls -l /proc/$proc/task/$thread/ 2>/dev/null| grep 'exe -> '| awk '{print $11}')
        if [ -z $NAME ]
        then
        NAME="/proc/$proc/task/$thread/exe"
        TYPE="unknown"
        DEVICE=""
        SIZE=""
        INODE=""
        else
        TYPE="REG"
        DEVICE="253,0"
        SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
        INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
        fi
        printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
        
        #mem
        FD="mem"
        TYPE="REG"
        IFS=$'\n'
        for maps_line_thread in $(cat /proc/$proc/task/$thread/maps 2>/dev/null| awk '{print $6}' | sed '/^$/d' | sed '1,/\[/d' | sed '/\[/d' | awk '! a[$0]++')
        do
          NAME="$maps_line_thread"
          DEVICE="253,0"
          SIZE=$(ls -lid $NAME 2>/dev/null| awk '{print $6}')
          INODE=$(ls -lid $NAME 2>/dev/null| awk '{print $1}')
          printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
        done
        
        IFS=$'\n'
        for line_thread in $(ls -l /proc/$proc/task/$thread/fd 2>/dev/null| grep -v '^total' | sort -k9 -n)  
        do
          #NAME
          NAME=$(echo $line_thread 2>/dev/null| awk '{print $11}')
          FD=$(echo $line_thread 2>/dev/null| awk '{print $9}')
          TYPE=""
          DEVICE=""
          SIZE=""
          INODE=""
          COMMAND=$(awk '{print $2}' /proc/$proc/task/$thread/stat | sed 's/[()]//g')
          printf "$FMT" "$COMMAND" "$PID" "$TID" "$USER" "$FD" "$TYPE" "$DEVICE" "$SIZE" "$INODE" "$NAME"
            
        done  
      fi
    done
      
  else
    continue
  fi
     
  
done
