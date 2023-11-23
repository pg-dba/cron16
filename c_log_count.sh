#!/bin/bash

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "set session statement_timeout to '1s'; SET client_min_messages TO error; SELECT count(*)::text as log_count FROM public.log_state();" 2>&1 | sed -n '1p' | ts '[pglog] ';
