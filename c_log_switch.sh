#!/bin/bash

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SET client_min_messages TO error; select public.log_switch()::text;" 2>&1 | sed -n '1p' | ts '[pglog] ';
