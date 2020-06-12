## Задание 2  
  
Обеспечить работоспособность приложения при включенном selinux.  
- Развернуть приложенный стенд  
https://github.com/mbfx/otus-linux-adm/blob/master/selinux_dns_problems/  
- Выяснить причину неработоспособности механизма обновления зоны (см. README);  
- Предложить решение (или решения) для данной проблемы;  
- Выбрать одно из решений для реализации, предварительно обосновав выбор;  
- Реализовать выбранное решение и продемонстрировать его работоспособность.
  
## Решение 
  
Разворачиваем стенд https://github.com/mbfx/otus-linux-adm/blob/master/selinux_dns_problems/  
  
Схема стенда  
- ns01 - DNS-сервер (192.168.50.10);  
- client - клиентская рабочая станция (192.168.50.15).  

При попытке удаленно (с рабочей станции 192.168.50.15) внести изменения в зону ddns.lab происходит следующее:
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
>
```
Заходим на сервер 192.168.50.10 и выясняем, в чем проблема  
  
Проверим статус сервиса named
```  
[root@ns01 ~]# systemctl status named
● named.service - Berkeley Internet Name Domain (DNS)
   Loaded: loaded (/usr/lib/systemd/system/named.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2020-06-11 21:54:09 UTC; 5min ago
  Process: 9315 ExecStart=/usr/sbin/named -u named -c ${NAMEDCONF} $OPTIONS (code=exited, status=0/SUCCESS)
  Process: 9313 ExecStartPre=/bin/bash -c if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/sbin/named-checkconf -z "$NAMEDCONF"; else echo "Checking of zone files is disabled"; fi (code=exited, status=0/SUCCESS)
 Main PID: 9317 (named)
   CGroup: /system.slice/named.service
           └─9317 /usr/sbin/named -u named -c /etc/named.conf

Jun 11 21:54:09 ns01 named[9317]: network unreachable resolving './NS/IN': 2001:dc3::35#53
Jun 11 21:54:09 ns01 named[9317]: network unreachable resolving './DNSKEY/IN': 2001:500:12::d0d#53
Jun 11 21:54:09 ns01 named[9317]: network unreachable resolving './NS/IN': 2001:500:12::d0d#53
Jun 11 21:54:09 ns01 named[9317]: managed-keys-zone/default: Key 20326 for zone . acceptance timer complete: key now trusted
Jun 11 21:54:09 ns01 named[9317]: resolver priming query complete
Jun 11 21:54:09 ns01 named[9317]: network unreachable resolving './DNSKEY/IN': 2001:503:c27::2:30#53
Jun 11 21:54:09 ns01 named[9317]: network unreachable resolving './DNSKEY/IN': 2001:500:a8::e#53
Jun 11 21:54:09 ns01 named[9317]: network unreachable resolving './DNSKEY/IN': 2001:500:1::53#53
Jun 11 21:54:09 ns01 named[9317]: managed-keys-zone/view1: Key 20326 for zone . acceptance timer complete: key now trusted
Jun 11 21:54:10 ns01 named[9317]: resolver priming query complete
```
  
Посмотрим лог аудита в читаемом формате для поиска причины  
```
audit2why < /var/log/audit/audit.log
```
```
type=AVC msg=audit(1591913473.230:2388): avc:  denied  { create } for  pid=9317 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.
```
Видим, что процесс с контекстом типа named_t пытается создать файл в контексте etc_t. SELinux блокирует это действие, что является причиной ошибки.  
  
### 1 способ (оптимальный). Перенос файлов зон в предусмотренный для них каталог.    
  
Посмотрим, какие контексты предусмотрены для named 
```
semanage fcontext -l | grep named
```
обращаем внимание на строку  
```
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0
```
Видно, что хранение файлов зон предусматривается в каталоге /var/named/, а зона ddns.lab., которую мы пытаемся обновить, лежит в каталоге /etc/named. 

Оптимальным решением будет перенести файлы зон в каталог /var/named, что позволит не устанавливать излишние права на запись в каталог /etc/named для процесса named.  
  
Перенесем файлы зон в каталог /var/named/ и отредактируем файл  /etc/named.conf  
  
Перезапустим named и проверим его статус  
  
``` 
systemctl restart named
systemctl status named

● named.service - Berkeley Internet Name Domain (DNS)
   Loaded: loaded (/usr/lib/systemd/system/named.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2020-06-11 22:29:55 UTC; 2s ago
  Process: 31702 ExecStop=/bin/sh -c /usr/sbin/rndc stop > /dev/null 2>&1 || /bin/kill -TERM $MAINPID (code=exited, status=0/SUCCESS)
  Process: 31715 ExecStart=/usr/sbin/named -u named -c ${NAMEDCONF} $OPTIONS (code=exited, status=0/SUCCESS)
  Process: 31713 ExecStartPre=/bin/bash -c if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/sbin/named-checkconf -z "$NAMEDCONF"; else echo "Checking of zone files is disabled"; fi (code=exited, status=0/SUCCESS)
 Main PID: 31717 (named)
   CGroup: /system.slice/named.service
           └─31717 /usr/sbin/named -u named -c /etc/named.conf 
```
  
Попробуем снова (с рабочей станции 192.168.50.15) внести изменения в зону ddns.lab:  
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
>
```
Теперь ошибки нет и файл named.ddns.lab.view1.jnl успешно создается в /var/named/  
  
[Ссылка на исправленный стенд](named_fixed)  
  
### 2 способ. Разрешение named на запись в каталог /etc/named. Неоптимальный, так как дает излишние права.  
  
Создадим модуль SELinux на основе анализа файла лога  
```  
audit2allow -M my_named --debug < /var/log/audit/audit.log
```

Посмотрим содержимое модуля  
```
cat my_named.te
```
```
module my_named 1.0;

require {
	type etc_t;
	type named_t;
	class file create;
}
#============= named_t ==============

#!!!! WARNING: 'etc_t' is a base type.
allow named_t etc_t:file create;
```
  
Установим модуль  
```
semodule -i my_named
```
  
Команда на клиенте снова выдает ошибку. Скомпилируем модуль еще раз.    
```
audit2allow -M my_named1 --debug < /var/log/audit/audit.log
```
  
Видим, что добавилось еще разрешение write.    
```
cat my_named1.te
```
```
module my_named1 1.0;

require {
	type etc_t;
	type named_t;
	class file { create write };
}

#============= named_t ==============
allow named_t etc_t:file write;

#!!!! This avc is allowed in the current policy
allow named_t etc_t:file create;
```
  
Удалим старый модуль
```
semodule -r my_named
```
Установим новый модуль
```
semodule -i my_named1.pp
```

Удалим пустой файл named.ddns.lab.view1.jnl
```
rm /etc/named/dynamic/named.ddns.lab.view1.jnl
```
Перезапустим named
```
systemctl restart named
```
Попробуем снова (с рабочей станции 192.168.50.15) внести изменения в зону ddns.lab:  
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
>
```
Теперь ошибки нет и файл named.ddns.lab.view1.jnl успешно создается в /etc/named/dynamic/    
  
