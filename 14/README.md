# Домашнее задание 14

## Задание 1<br><br>
Настраиваем центральный сервер для сбора логов
в вагранте поднимаем 2 машины web и log
на web поднимаем nginx
на log настраиваем центральный лог сервер на любой системе на выбор
- journald
- rsyslog
- elk
настраиваем аудит следящий за изменением конфигов нжинкса

все критичные логи с web должны собираться и локально и удаленно
все логи с nginx должны уходить на удаленный сервер (локально только критичные)
логи аудита должны также уходить на удаленную систему

Примечание к заданию 1<br>
Стенд разворачивается из [Vagrantfile](1/Vagrantfile) с помощью ролей ansible [log.yml](1/log.yml) (сервер ELK 192.168.11.101) и [web.yml](1/web.yml) (Nginx 192.168.11.102). После установки для просмотра логов используется Kibana по адресу 192.168.11.101:5601<br>
Настройки отображения логов в Kibana: <br>
раздел Management - Kibana - Index Patterns - Create index pattern - 
в поле index pattern указать индекс (в данном примере filebeat-7.5.1-2020.01.05) - Next step - На вкладке Configure settings в поле Time Filter filed name выбрать из списка @timestamp - Create index pattern - Переходим в раздел Discover и там отображаются логи с удаленной машины

## Задание 2<br><br>
развернуть еще машину elk
и таким образом настроить 2 центральных лог системы elk И какую либо еще
в elk должны уходить только логи нжинкса
во вторую систему все остальное

Примечание к заданию 2<br>
Стенд разворачивается из [Vagrantfile](2/Vagrantfile) с помощью ролей ansible [log.yml](2/log.yml) (сервер ELK 192.168.11.101),  [web.yml](2/web.yml) (Nginx 192.168.11.102) и [rsyslog.yml](2/rsyslog.yml) (сервер Rsyslog 192.168.11.103)<br>
В ELK идут только файлы /var/log/nginx/error.log и /var/log/nginx/access.log<br>
Для генерации записей в лог-файлах открыть в браузере http://192.168.11.102, на котором установлен nginx. <br>
Просмотр логов в ELK<br>
192.168.11.101:5601 - Management - Kibana - Index Patterns - Create index pattern
в поле index pattern указать индекс (в данном примере filebeat-7.5.1-2020.01.05) - Next step - На вкладке Configure settings в поле Time Filter filed name выбрать из списка @timestamp - Create index pattern
Переходим в раздел Discover и там отображаются логи с удаленной машины

Для хранения остальных логов используем rsyslog, установленную по адресу 192.168.11.103

Логи с сервера web (192.168.11.102) отправляются на сервер rsyslog (192.168.11.103) и хранятся там в каталоге /var/log/remotehosts/web
