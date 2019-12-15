# Домашнее задание 13

Создайте свой [кастомный образ nginx на базе alpine](1/Dockerfile). После запуска nginx должен
отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)<br>
https://hub.docker.com/r/root1604/alpine-nginx

Определите разницу между контейнером и образом<br>
Образ - это шаблон для создания контейнеров.<br>
В образе все слои доступны только для чтения.<br>
В контейнере помимо слоев из образа содержится еще один слой, доступный на запись.<br>
<br>
Можно ли в контейнере собрать ядро?<br>
Можно.<br>
<br>
Задание со * (звездочкой)<br>
Создайте кастомные образы [nginx](1/Dockerfile) и [php](2/php-fpm/Dockerfile), объедините их в [docker-compose](2/docker-compose.yml).
После запуска nginx должен показывать php info.
Все собранные образы должны быть в docker hub<br>
[nginx](https://hub.docker.com/r/root1604/alpine-nginx)<br>
[php-fpm](https://hub.docker.com/r/root1604/alpine-php-fpm)<br>
<br>
Инструкция по запуску стенда<br>
<br>
DNS-имя docker.local должно разрешаться в ip-адрес хоста (по которому докер-хост доступен по сети), на котором будет запускаться стенд.<br>
<br>
Структура файлов<br>
<br>
tree<br>
.<br>
├── code<br>
│   └── index.php<br>
├── docker-compose.yml<br>
├── php-fpm<br>
│   └── Dockerfile<br>
└── site.conf<br>

<br>
запуск из текущей папки<br>
<br>
docker-compose up -d<br>
<br>
В браузере по адресу docker.local должна отобразиться страница с phpinfo.<br>

