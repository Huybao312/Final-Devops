#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
db_container
mkdir -p "$BACKUP_DIR"
exec > >(tee -a "$BACKUP_DIR/restore-verification.log") 2>&1
suffix="$(date -u +%Y%m%d%H%M%S)_$$"
trial="week3_restore_trial_$suffix"
result="week3_restore_result_$suffix"
signature() { sql "$1" -Atc "SELECT count(*) || '|' || md5(coalesce(string_agg(row_to_json(t)::text, ',' ORDER BY id), '')) FROM public.tasks t;"; }
log 'Take a production snapshot; all destructive demonstration operations use an isolated database.'
production_archive="$(bash "$ROOT/scripts/week3/backup.sh" todo)"
bash "$ROOT/scripts/week3/restore.sh" "$production_archive" "$trial"
sql "$trial" -c "INSERT INTO public.tasks(title,description) VALUES ('week3-restore-proof-$suffix','Synthetic data for restore demo');"
before="$(signature "$trial")"
trial_archive="$(bash "$ROOT/scripts/week3/backup.sh" "$trial")"
sql "$trial" -c "DELETE FROM public.tasks WHERE title='week3-restore-proof-$suffix';"
after_delete="$(signature "$trial")"
[[ "$before" != "$after_delete" ]]
bash "$ROOT/scripts/week3/restore.sh" "$trial_archive" "$result"
restored="$(signature "$result")"
printf 'Before deletion: %s\nAfter deletion: %s\nAfter restore: %s\n' "$before" "$after_delete" "$restored"
[[ "$before" == "$restored" ]]
sql "$result" -c "SELECT id,title FROM public.tasks WHERE title='week3-restore-proof-$suffix';"
log "PASS: restored row count and full task checksum match; production was not modified. Verification DBs: $trial $result"
log 'Retain databases for evidence; remove them later using dropdb only after checking their names.'
