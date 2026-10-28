#!/bin/sh
set -eu
psql -v ON_ERROR_STOP=1 --username postgres --dbname todo \
  --set=app_password="$TODO_APP_PASSWORD" <<'SQL'
CREATE ROLE todo_owner NOLOGIN;
CREATE ROLE todo_app LOGIN PASSWORD :'app_password';
ALTER DATABASE todo OWNER TO todo_owner;
ALTER TABLE public.tasks OWNER TO todo_owner;
ALTER SEQUENCE public.tasks_id_seq OWNER TO todo_owner;
REVOKE ALL ON DATABASE todo FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE todo TO todo_app;
GRANT USAGE ON SCHEMA public TO todo_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.tasks TO todo_app;
GRANT USAGE, SELECT ON SEQUENCE public.tasks_id_seq TO todo_app;
SQL
