#!/bin/bash
# need backups directory mapped /pgbackups

# если параметров 1 или 2 ,и второй только из цифр
if [[ ("$#" -eq 1) || ( ("$#" -eq 2) && ($2 =~ ^[[:digit:]]+$) ) ]]; then

backupDatabase=$1
#backupName="${backupDatabase}_$(date +%FT%T%z).dump"
backupName="${backupDatabase}_$(date +%A).dump"

zbxskey='pgsql.backup.start["'${backupDatabase}'"]'
zbxfkey='pgsql.backup.finish["'${backupDatabase}'"]'
zbxrkey='pgsql.backup.rotation["'${backupDatabase}'"]'
zbxtkey='pgsql.backup.time["'${backupDatabase}'"]'

echo "[pgdump]  [${backupDatabase}] backup started"
bkp_start=$EPOCHSECONDS
if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxskey}" -o "$(date --iso-8601=seconds)" 2>&1 1>/dev/null
fi

PGPASSWORD=${PASSWORD} pg_dump -h ${HOST} -p ${PORT} -U ${USERNAME} -Fc -f "/pgbackups/${backupName}" "${backupDatabase}" 2>&1
RC=$?

echo "[pgdump]  [${backupDatabase}] backup finished. RC=${RC}"
bkp_finish=$EPOCHSECONDS

if [[ $RC -eq 0 ]] ; then
if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxfkey}" -o "$(date --iso-8601=seconds)" 2>&1 1>/dev/null
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxtkey}" -o "$((${bkp_finish}-${bkp_start}))" 2>&1 1>/dev/null
fi
fi

if [[ ("$#" -eq 2) ]]; then

saves=$2

rm -f $(ls -1t --time-style=long-iso /pgbackups/${backupDatabase}_*.dump 2>/dev/null | sed -n "$((${saves}+1)),\$p")

echo "[pgdump]  [${backupDatabase}] backup file $2 rotation completed."

if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxrkey}" -o "${saves}" 2>&1 1>/dev/null
fi

fi

fi
