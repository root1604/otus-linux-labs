#!/bin/bash

# Скрипт считывает данные из LOGFILE, проверяет, есть ли новые строки,
# копирует новые строки в BUFERFILE, сохраняет последнюю обработанную строку в LAST_PROCESSED_LINE_FILE
# выбирает статистику по всем строкам из BUFERFILE, отправляет сообщение со статистикой на EMAIL
# Для отправки сообщения каждый час нужно запуск файла скрипта прописать в crontab
# crontab -e
# 0 * * * * ~/nginx/nginx.sh

# exit 0  - все ОК
# exit 1  - нет новых строк в LOGFILE
# exit 2  - выполнение скрипта было прервано
# exit 3  - отсутствует LOGFILE
# exit 4  - попытка мультизапуска

LOCKFILE=lockfile
LOGFILE=~/nginx/access.log
BUFERFILE=buferfile
LAST_PROCESSED_LINE_FILE=lastlinefile
EMAIL_TO=root@otuslinux.loc
EMAIL_FROM=vagrant@otuslinux.loc
declare -i LAST_PROCESSED_LINE_NUMBER
declare -i LAST_LINE_NUMBER_IN_LOGFILE

reading_logfile(){
	START_DATE=$(head -n 1 $BUFERFILE | awk -F [ '{ print $2 }' | awk -F ] '{ print $1 }')
	FINISH_DATE=$(tail -n 1 $BUFERFILE | awk -F [ '{ print $2 }' | awk -F ] '{ print $1 }')
        echo "==================================================================================">message
	echo "Временной диапазон: $START_DATE - $FINISH_DATE"					 >>message
	echo "==================================================================================">>message
	echo "==================================================================================">>message
	echo "IP-адреса с наибольшим количеством запросов"					 >>message
	echo "==================================================================================">>message	
	awk '{print "requests from " $1}' $BUFERFILE|sort |uniq -c |sort -nr |head		 >>message	
	echo "==================================================================================">>message
	echo "Наиболее часто запрашиваемые данные"						 >>message
	echo "==================================================================================">>message
        awk -F \" '{print "requests to " $2}' $BUFERFILE |sort |uniq -c |sort -nr |head		 >>message
	echo "==================================================================================">>message
	echo "Коды ответа и ошибок HTTP"							 >>message
	echo "==================================================================================">>message
        awk '{print "responses of status code " $9}' $BUFERFILE | sort | uniq -c | sort -rn	 >>message	
	mail -s "Отчет веб-сервера за $START_DATE - $FINISH_DATE" -r $EMAIL_FROM $EMAIL_TO < message
	tail -n 1 $BUFERFILE > $LAST_PROCESSED_LINE_FILE
	rm -f $BUFERFILE
}

if ( set -o noclobber; echo "$$" > "$LOCKFILE") 2> /dev/null;
        then
                trap 'rm -f "$LOCKFILE"; exit 2' INT TERM EXIT
                        if [ -f $LOGFILE ]
                        then
                        	if [ -s $LAST_PROCESSED_LINE_FILE ] 
				then
					LAST_PROCESSED_LINE=$(sed -n 1p $LAST_PROCESSED_LINE_FILE)
					if [ -n '$LAST_PROCESSED_LINE' ]
					then
						LAST_PROCESSED_LINE_NUMBER=$(grep -n -F "$LAST_PROCESSED_LINE" $LOGFILE | cut -d : -f 1)
						LAST_LINE_NUMBER_IN_LOGFILE=$(wc $LOGFILE | awk '{ print $1 }')
						if [ $LAST_PROCESSED_LINE_NUMBER = $LAST_LINE_NUMBER_IN_LOGFILE ]
						then
						echo "There are not new lines in the logfile. Check the service." | mail -s "There are not new lines in the logfile. Check the service." -r $EMAIL_FROM $EMAIL_TO
						exit 1
						else
						awk -v pattern=$LAST_PROCESSED_LINE_NUMBER 'NR>pattern' $LOGFILE > $BUFERFILE
						reading_logfile
						fi
					else
						cp $LOGFILE $BUFERFILE
						reading_logfile
					fi
				else
					cp $LOGFILE $BUFERFILE
					reading_logfile
				fi      

                        else
                                echo "Failed to open $LOGFILE"
				exit 3
                        fi


                        rm -f "$LOCKFILE"
                trap - INT TERM EXIT
        else
                echo "Failed to acquire lockfile: $LOCKFILE."
                echo "Held by $(cat $LOCKFILE)"
		exit 4
fi

exit 0
