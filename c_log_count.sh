#!/bin/bash

PGPASSWORD=${PASSWORD} PGOPTIONS="-c geqo=off -c statement_timeout=5min -c client_min_messages=error" psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT count(*)::text as log_count FROM public.log_state();" 2>&1 | sed -n '1p' | ts '[pglog] ';
