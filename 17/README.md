# Домашнее задание 17
Сценарии iptables  
1) реализовать knocking port  
- centralRouter может попасть на ssh inetrRouter через knock скрипт  
пример в материалах  
2) добавить inetRouter2, который виден(маршрутизируется) с хоста  
3) запустить nginx на centralServer  
4) пробросить 80й порт на inetRouter2 8080  
5) дефолт в инет оставить через inetRouter   

Структура сети  
  
  
centralServer  -----> centralRouter   --    inetRouter       --> internet  
    (nginx)           192.168.255.2         192.168.255.1      
 192.168.0.2          192.168.0.1                             
                      192.168.0.33     --   inetRouter2      <-- http://localhost:8080  
                      192.168.0.65          192.168.255.3  
                      

Стенд разворачивается из [Vagrantfile](Vagrantfile)   
с помощью ролей ansible [inetRouter.yml](inetRouter.yml)  
[centralRouter.yml](centralRouter.yml)  
[centralServer.yml](centralServer.yml)   
[inetRouter2.yml](inetRouter2.yml)      

После развертывания на inetRouter(192.168.255.1) можно зайти c centralRouter(192.168.255.2), предварительно залогинившись под пользователем vagrant и запустив скрипт
```
/home/vagrant/knock.sh 192.168.255.1 8881 7777 9991
  
```                   
После этого можно подключаться по ssh
```
ssh 192.168.255.1
  
```
    
Сервер nginx, установленный на centralServer(192.168.0.2) доступен с машины, на которой запускается стенд, по адресу http://localhost:8080 
