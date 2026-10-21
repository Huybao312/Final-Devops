-- Todo Task Manager schema (PostgreSQL).
-- Applied by scripts/setup-db.sh as the PostgreSQL superuser.
-- The application role receives DML privileges only; see scripts/setup-db.sh.

CREATE TABLE IF NOT EXISTS public.tasks (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       text NOT NULL CHECK (length(btrim(title)) > 0),
    description text NOT NULL DEFAULT '',
    completed   boolean NOT NULL DEFAULT false,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tasks_completed_created_at_idx
    ON public.tasks (completed, created_at DESC);
