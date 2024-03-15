FROM debian:bullseye-slim
#FROM debian:latest
# https://github.com/renskiy/cron-docker-image/tree/master/debian
# https://habr.com/ru/company/redmadrobot/blog/305364/

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

#ENV TZ="Europe/Moscow"

RUN set -ex \
    && apt-get clean && apt-get update \
    && apt-get -y install lsb-release gnupg2 apt-utils wget
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get clean && apt-get update \
    && apt-get -y install postgresql-client-16 iputils-ping dnsutils \
    && apt-get -y install pgbadger moreutils nano

RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install postfix mutt && unset DEBIAN_FRONTEND
COPY main.cf /etc/postfix/main.cf

RUN wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix/zabbix-sender_6.4.12-1%2Bdebian11_amd64.deb \
    && dpkg -i zabbix-sender_6.4.12-1+debian11_amd64.deb \
    && apt-get -y install zabbix-sender

RUN set -ex \
    && apt-get clean && apt-get update \
# install cron
    && apt-get install -y cron \
    && rm -rf /var/lib/apt/lists/* \
# making logging pipe
    && mkfifo --mode 0666 /var/log/cron.log \
# make pam_loginuid.so optional for cron
# see https://github.com/docker/docker/issues/5663#issuecomment-42550548
    && sed --regexp-extended --in-place \
    's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' \
    /etc/pam.d/cron

RUN apt-get clean all

RUN echo 'alias nocomments="sed -e :a -re '"'"'s/<\!--.*?-->//g;/<\!--/N;//ba'"'"' | sed -e :a -re '"'"'s/\/\*.*?\*\///g;/\/\*/N;//ba'"'"' | grep -v -P '"'"'^\s*(#|;|--|//|$)'"'"'"' >> ~/.bashrc

COPY start-cron /usr/sbin/

# scripts for cron
COPY *.sh /etc/cron.d/
RUN chmod 755 /etc/cron.d/*.sh

# для send_pgbadger.sh
RUN mkdir -p /pglog
VOLUME /pglog

# для c_pgdump.sh
RUN mkdir -p /pgbackups
VOLUME /pgbackups

# для рабочий каталог для файлов tasks
RUN mkdir -p /cronwork
RUN chmod 777 /cronwork
VOLUME /cronwork

WORKDIR /etc/cron.d

ENTRYPOINT ["/etc/cron.d/docker-entrypoint.sh"]

CMD ["start-cron"]
