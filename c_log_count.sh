#!/bin/bash
# c_log_count.sh
PGPASSWORD=${PASSWORD} PGOPTIONS="-c geqo=off -c statement_timeout=5min -c client_min_messages=error" psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT (SELECT count(*)::text FROM public.log_state()) as log_count ,(SELECT count(*)::text FROM public.log_state() WHERE datacheck=false) as bad_log_count;" 2>&1 | ts '[pglog] ';
