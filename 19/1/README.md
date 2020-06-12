##  Задание 1  
  
Запустить nginx на нестандартном порту 3-мя разными способами:  
- переключатели setsebool;  
- добавление нестандартного порта в имеющийся тип;  
- формирование и установка модуля SELinux.  
  
## Решение  
  
1. Установим nginx  
yum install epel-release nginx -y  
  
Запустим nginx  
systemctl enable nginx --now  
  
Убедимся, что nginx запущен  
systemctl status nginx  
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-06-09 12:00:51 EDT; 9s ago
  Process: 1473 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 1470 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 1469 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 1475 (nginx)
   CGroup: /system.slice/nginx.service
           ├─1475 nginx: master process /usr/sbin/nginx
           └─1476 nginx: worker process

Jun 09 12:00:51 nginx.local systemd[1]: Starting The nginx HTTP and reverse ....
Jun 09 12:00:51 nginx.local nginx[1470]: nginx: the configuration file /etc/...k
Jun 09 12:00:51 nginx.local nginx[1470]: nginx: configuration file /etc/ngin...l
Jun 09 12:00:51 nginx.local systemd[1]: Failed to parse PID from file /run/n...t
Jun 09 12:00:51 nginx.local systemd[1]: Started The nginx HTTP and reverse p....
Hint: Some lines were ellipsized, use -l to show in full.
```
  
  
Убедимся, что nginx слушает 80 порт  
ss -tulpn | column -t | grep nginx  
  
```
tcp    LISTEN  0       128     *:80           *:*           users:(("nginx",pid=1476,fd=6),("nginx",pid=1475,fd=6))
tcp    LISTEN  0       128     [::]:80        [::]:*        users:(("nginx",pid=1476,fd=7),("nginx",pid=1475,fd=7))
```
  
Настроим, чтобы nginx слушал на порту 8764 вместо 80  
Для этого пропишем в файле /etc/nginx/nginx.conf строку     
```
listen       8764 default_server;
```
  
Перезапустим nginx  
systemctl restart nginx  
  
Убедимся, что сервис не запустился  
systemctl status nginx -l  
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2020-06-09 12:43:34 EDT; 8s ago
  Process: 1632 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 1804 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 1803 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 1634 (code=exited, status=0/SUCCESS)

Jun 09 12:43:34 nginx.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 09 12:43:34 nginx.local nginx[1804]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 09 12:43:34 nginx.local nginx[1804]: nginx: [emerg] bind() to 0.0.0.0:8764 failed (13: Permission denied)
Jun 09 12:43:34 nginx.local nginx[1804]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jun 09 12:43:34 nginx.local systemd[1]: nginx.service: control process exited, code=exited status=1
Jun 09 12:43:34 nginx.local systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Jun 09 12:43:34 nginx.local systemd[1]: Unit nginx.service entered failed state.
Jun 09 12:43:34 nginx.local systemd[1]: nginx.service failed.
```
  
Замечаем, что не удалось привязать сервис nginx к порту 8764 
```
Jun 09 12:43:34 nginx.local nginx[1804]: nginx: [emerg] bind() to 0.0.0.0:8764 failed (13: Permission denied)
```
  
Установим утилиты для работы с selinux  
yum install setools-console policycoreutils-python -y  
  
Посмотрим лог аудита в читаемом формате для поиска причины  
audit2why < /var/log/audit/audit.log  
  
```
type=AVC msg=audit(1591721014.805:212): avc:  denied  { name_bind } for  pid=1804 comm="nginx" src=8764 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
  
Видим, что процесс nginx с контекстом типа httpd_t пытается запуститься на порте с контекстом типа unreserved_port_t. Поэтому selinux запрещает запуск сервиса.    
  
Решение проблемы  
  
### Способ 1 (оптимальный). Добавим порт 8764 tcp в тип httpd_t. Этот способ оптимальный, так как мы добавляем только необходимые минимальные разрешения.  
  
Посмотрим, какие порты разрешены сейчас  
semanage port -l | grep http  
```
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
  
Внесем изменения  
semanage port -a -t http_port_t -p tcp 8764  
  
Посмотрим, какие порты разрешены сейчас  
semanage port -l | grep http  
```
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      8764, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
  
Видим, что порт 8764 появился в списке  
  
Запускаем сервис nginx  
systemctl start nginx  
  
Проверяем статус сервиса  
systemctl status nginx -l  
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-06-09 12:48:17 EDT; 37s ago
  Process: 1830 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 1827 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 1826 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 1832 (nginx)
   CGroup: /system.slice/nginx.service
           ├─1832 nginx: master process /usr/sbin/ngin
           └─1833 nginx: worker proces

Jun 09 12:48:17 nginx.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 09 12:48:17 nginx.local nginx[1827]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 09 12:48:17 nginx.local nginx[1827]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 09 12:48:17 nginx.local systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jun 09 12:48:17 nginx.local systemd[1]: Started The nginx HTTP and reverse proxy server.
```
  
Убедимся, что nginx слушает 8764 порт  
ss -tulpn | column -t | grep nginx 
```
tcp    LISTEN  0       128     *:8764         *:*           users:(("nginx",pid=1833,fd=6),("nginx",pid=1832,fd=6))
tcp    LISTEN  0       128     [::]:80        [::]:*        users:(("nginx",pid=1833,fd=7),("nginx",pid=1832,fd=7))
```
  
### Способ 2. Через параметризованные политики (при таком способе устанавливается разрешение запускать nginx на любом порту, что дает больше разрешений, чем нужно)  
Удалим порт 8765 из httpd_t  
semanage port -d -t http_port_t -p tcp 8764  
  
Перезапустим nginx и убедимся, что он не запускается  
systemctl restart nginx  
systemctl status nginx -l  
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2020-06-09 13:11:36 EDT; 11s ago
  Process: 1830 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 11607 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 11605 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 1832 (code=exited, status=0/SUCCESS)

Jun 09 13:11:36 nginx.local systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Jun 09 13:11:36 nginx.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 09 13:11:36 nginx.local nginx[11607]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 09 13:11:36 nginx.local nginx[11607]: nginx: [emerg] bind() to 0.0.0.0:8764 failed (13: Permission denied)
Jun 09 13:11:36 nginx.local nginx[11607]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jun 09 13:11:36 nginx.local systemd[1]: nginx.service: control process exited, code=exited status=1
Jun 09 13:11:36 nginx.local systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Jun 09 13:11:36 nginx.local systemd[1]: Unit nginx.service entered failed state.
Jun 09 13:11:36 nginx.local systemd[1]: nginx.service failed.
```
  
Посмотрим лог аудита в читаемом формате для поиска причины
audit2why < /var/log/audit/audit.log  
```
type=AVC msg=audit(1591722696.062:233): avc:  denied  { name_bind } for  pid=11607 comm="nginx" src=8764 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
  
Из лога видим, что нужно разрешить параметр nis_enabled  
  
Разрешим его  
setsebool -P nis_enabled 1  
  
запускаем nginx и проверяем статус  
systemctl start nginx  
systemctl status nginx -l  
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-06-09 13:16:29 EDT; 3s ago
  Process: 11628 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 11625 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 11624 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 11630 (nginx)
   CGroup: /system.slice/nginx.service
           ├─11630 nginx: master process /usr/sbin/ngin
           └─11631 nginx: worker proces

Jun 09 13:16:29 nginx.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 09 13:16:29 nginx.local nginx[11625]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 09 13:16:29 nginx.local nginx[11625]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 09 13:16:29 nginx.local systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jun 09 13:16:29 nginx.local systemd[1]: Started The nginx HTTP and reverse proxy server.
```
  
ss -tulpn | column -t | grep nginx  
```
tcp    LISTEN  0       128     *:8764         *:*           users:(("nginx",pid=11631,fd=6),("nginx",pid=11630,fd=6))
tcp    LISTEN  0       128     [::]:80        [::]:*        users:(("nginx",pid=11631,fd=7),("nginx",pid=11630,fd=7))
```
  
### Способ 3. Формирование и установка модуля SELinux (при таком способе устанавливается разрешение запускать nginx на любом порту, что дает больше разрешений, чем нужно)  
  
Вернем параметр nis_enabled в 0  
setsebool -P nis_enabled 0  
  
Перезапустим nginx и убедимся, что он не запускается  
systemctl restart nginx  
systemctl status nginx -l  
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2020-06-09 13:19:55 EDT; 1min 30s ago
  Process: 11628 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 11658 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 11656 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 11630 (code=exited, status=0/SUCCESS)

Jun 09 13:19:54 nginx.local systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Jun 09 13:19:54 nginx.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 09 13:19:55 nginx.local nginx[11658]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 09 13:19:55 nginx.local nginx[11658]: nginx: [emerg] bind() to 0.0.0.0:8764 failed (13: Permission denied)
Jun 09 13:19:55 nginx.local nginx[11658]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jun 09 13:19:55 nginx.local systemd[1]: nginx.service: control process exited, code=exited status=1
Jun 09 13:19:55 nginx.local systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Jun 09 13:19:55 nginx.local systemd[1]: Unit nginx.service entered failed state.
Jun 09 13:19:55 nginx.local systemd[1]: nginx.service failed.
```
  
Очищаем лог   
echo > /var/log/audit/audit.log  
  
Запускаем nginx, чтобы в лог-файле оказалась только нужная информация  
systemctl start nginx  
  
Формируем модуль на основе анализа файла лога  
ausearch -c 'nginx' --raw | audit2allow -M my-nginx  
  
Посмотрим содержимое модуля  
cat my-nginx.te  
```

module my-nginx 1.0;

require {
        type httpd_t;
        type unreserved_port_t;
        class tcp_socket name_bind;
}

#============= httpd_t ==============

#!!!! This avc can be allowed using the boolean 'nis_enabled'
allow httpd_t unreserved_port_t:tcp_socket name_bind;
```
  
Установим модуль  
semodule -i my-nginx.pp  
  
Запустим nginx и проверим статус  
systemctl start nginx  
systemctl status nginx -l  
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-06-09 13:37:11 EDT; 7s ago
  Process: 11710 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 11706 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 11705 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 11712 (nginx)
   CGroup: /system.slice/nginx.service
           ├─11712 nginx: master process /usr/sbin/ngin
           └─11713 nginx: worker proces

Jun 09 13:37:11 nginx.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 09 13:37:11 nginx.local nginx[11706]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 09 13:37:11 nginx.local nginx[11706]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 09 13:37:11 nginx.local systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jun 09 13:37:11 nginx.local systemd[1]: Started The nginx HTTP and reverse proxy server.
```
  
ss -tulpn | column -t | grep nginx  
```
tcp    LISTEN  0       128     *:8764         *:*           users:(("nginx",pid=11713,fd=6),("nginx",pid=11712,fd=6))
tcp    LISTEN  0       128     [::]:80        [::]:*        users:(("nginx",pid=11713,fd=7),("nginx",pid=11712,fd=7))
```

