# cron

https://habr.com/ru/company/redmadrobot/blog/305364/

Запуск cron внутри Docker-контейнера

https://hub.docker.com/r/renskiy/cron/

https://github.com/renskiy/cron-docker-image

В контейнер необходимо передавать все строки crontab как ARG<BR>
В контейнере уже дожны быть все скрипты. Скрипты должны быть универсальными. Все отличия д.б. вынесены в параметры.<BR>
