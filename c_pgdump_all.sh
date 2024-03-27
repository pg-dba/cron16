#!/bin/bash
# c_pgdump_all.sh

fprefix="${HOST}_$(date '+%Y-%m-%d_%H-%M-%S_%z')"

zbxfkey='pgsql.pg_dump_all.backup.finish'
zbxrkey='pgsql.pg_dump_all.backup.rotation'
zbxckey='pgsql.pg_dump_all.backup.rc'
zbxhkey='pgsql.pg_dump_all.transfer.finish'

IFS="|";
echo "[pgdump]  PGDUMPALL ${HOST} started."  2>&1;

PGPASSWORD=${PASSWORD} pg_dumpall -h ${HOST} -p ${PORT} -U ${USERNAME} --schema-only -f "/pgbackups/${fprefix}_dumpall_full.sql" 2>&1
RC=$?
echo "[pgdump]  PGDUMPALL ${HOST}. pg_dumpall schema-only finished. RC=${RC}"

PGPASSWORD=${PASSWORD} pg_dumpall -h ${HOST} -p ${PORT} -U ${USERNAME} --globals-only -f "/pgbackups/${fprefix}_dumpall_global.sql" 2>&1
RC=$?
echo "[pgdump]  PGDUMPALL ${HOST}. pg_dumpall globals-only finished. RC=${RC}"

cmd1="SELECT datname FROM pg_database WHERE datistemplate = false;";
DBs=($(PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d postgres -c "${cmd1}" -XAt | tr -s '\n' '|' | tr -d '\r'));

for dbName in ${!DBs[*]}; do

PGPASSWORD=${PASSWORD} pg_dump -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBs[$dbName]} --schema-only -f "/pgbackups/${fprefix}_${DBs[$dbName]}_schema-only.sql" 2>&1 1>/dev/null;
RC=$?
echo "[pgdump]  PGDUMPALL ${HOST}. pg_dump db:${DBs[$dbName]} schema-only finished. RC=${RC}"

done;

find /pgbackups/ -name "${fprefix}*.sql" | tar czf /pgbackups/${fprefix}.tgz --files-from=- &>/dev/null;
#tar -tvf /pgbackups/${fprefix}.tgz &>/dev/null;
rm -f /pgbackups/${fprefix}*.sql
RC=$?

bkp_finish=$(date +%s)

if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxckey}" -o "${RC}" 2>&1 1>/dev/null
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxfkey}" -o "${bkp_finish}" 2>&1 1>/dev/null
fi

echo "[pgdump]  PGDUMPALL ${HOST} finished."

# если параметр 1 и он только из цифр
if [[ ("$#" -eq 1) && ($1 =~ ^[[:digit:]]+$) ]]; then

saves=$1

rm -f $(ls -1t --time-style=long-iso /pgbackups/${HOST}_*.tgz 2>/dev/null | sed -n "$((${saves}+1)),\$p")

echo "[pgdump]  PGDUMPALL ${HOST}. $1 rotation completed."

if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxrkey}" -o "${saves}" 2>&1 1>/dev/null
fi

fi

if [ -n "${MINIO_ENDPOINT_URL}" ]; then

echo "[pgdump]  PGDUMPALL transfer started"
tr_start=$(date +%s)

mc cp /pgbackups/${fprefix}.tgz ${MINIO_BUCKET}/ 2>&1 1>/dev/null
RC=$?

echo "[pgdump]  PGDUMPALL transfer finished. RC=${RC}"
tr_finish=$(date +%s)

if [[ (-n "${ZBX_SERVERS}") && (${RC} -eq 0) ]]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxhkey}" -o "${tr_finish}" 2>&1 1>/dev/null
fi

fi
