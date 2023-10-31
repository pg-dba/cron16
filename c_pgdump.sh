#!/bin/bash
# need backups directory mapped /pgbackups

# если параметров 1 или 2 ,и второй только из цифр
if [[ ("$#" -eq 1) || ( ("$#" -eq 2) && ($2 =~ ^[[:digit:]]+$) ) ]]; then

backupDatabase=$1
#backupName="${backupDatabase}_$(date +%FT%T%z).dump"
backupName="${backupDatabase}_$(date +%A).dump"

echo "[pgdump]  [${backupDatabase}] backup started"

PGPASSWORD=${PASSWORD} pg_dump -h ${HOST} -p ${PORT} -U ${USERNAME} -Fc -f "/pgbackups/${backupName}" "${backupDatabase}" 2>&1
RC=$?

echo "[pgdump]  [${backupDatabase}] backup finished. RC=${RC}"

if [[ ("$#" -eq 2) ]]; then

saves=$2

rm -f $(ls -1t --time-style=long-iso /pgbackups/${backupDatabase}_*.dump 2>/dev/null | sed -n "$((${saves}+1)),\$p")

echo "[pgdump]  [${backupDatabase}] backup file $2 rotation completed."

fi

fi
