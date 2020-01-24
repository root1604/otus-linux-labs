# Домашнее задание 16

LDAP
1. Установить FreeIPA
2. Написать playbook для конфигурации клиента
3*. Настроить авторизацию по ssh-ключам

Стенд разворачивается из [Vagrantfile](Vagrantfile) с помощью ролей ansible [freeipa.yml](freeipa.yml) и [client.yml](client.yml)

Сервер freeipa.example.local 192.168.11.101<br>
Клиент client.example.local 192.168.11.102<br><br>

Для проверки залогинимся как root на клиенте и зайдем по ssh с клиента на сервер (пароль на ssh-ключ 'password')<br>
\# ssh -vvv admin@freeipa.example.local

После этого выйдем и зайдем, авторизуясь через kerberos (пароль 'password')<br>
\# kinit admin<br>
\# ssh -vvv admin@freeipa.example.local
