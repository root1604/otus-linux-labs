# Домашнее задание 12

Настроить стенд Vagrant с двумя виртуальными машинами server и client.

Настроить политику бэкапа директории /etc с клиента:
1) Полный бэкап - раз в день
2) Инкрементальный - каждые 10 минут
3) Дифференциальный - каждые 30 минут

Запустить систему на два часа. Для сдачи ДЗ приложить [list jobs](list_jobs.txt), [list files jobid=<id>](list_files.txt)
[и сами конфиги bacula-*](roles/bacula_server/files/)

Стенд разворачивается из [Vagrantfile](Vagrantfile) с помощью ролей ansible [bacula_server.yml](bacula_server.yml) и [bacula_client.yml](bacula_client.yml)
