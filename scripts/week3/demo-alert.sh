#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
mkdir -p "$BACKUP_DIR"
exec > >(tee -a "$BACKUP_DIR/alert-verification.log") 2>&1
curl -fsS http://127.0.0.1/health >/dev/null
curl -fsS http://127.0.0.1:9090/-/ready >/dev/null
trap 'bash "$ROOT/scripts/week3/app.sh" start' EXIT
log 'Stopping only the app; DB stays running. Recovery is registered in EXIT trap.'
bash "$ROOT/scripts/week3/app.sh" stop
firing=0
for attempt in {1..12}; do
  if curl -fsS http://127.0.0.1:9090/api/v1/alerts | python3 -c 'import json,sys; alerts=json.load(sys.stdin)["data"]["alerts"]; sys.exit(0 if any(a["labels"].get("alertname")=="TodoAppUnavailable" and a["state"]=="firing" for a in alerts) else 1)'; then
    firing=1
    log 'PASS TodoAppUnavailable FIRING; capture Prometheus Alerts/dashboard now.'
    log 'Keeping alert active for 20 seconds for screenshot capture.'
    sleep 20
    break
  fi
  sleep 10
done
SINCE=5m bash "$ROOT/scripts/week3/app.sh" logs
bash "$ROOT/scripts/week3/app.sh" start
trap - EXIT
[[ "$firing" == 1 ]] || { log 'FAIL: did not observe FIRING'; exit 1; }
for attempt in {1..12}; do
  if curl -fsS http://127.0.0.1/health >/dev/null && curl -fsS http://127.0.0.1:9090/api/v1/alerts | python3 -c 'import json,sys; alerts=json.load(sys.stdin)["data"]["alerts"]; sys.exit(1 if any(a["labels"].get("alertname")=="TodoAppUnavailable" for a in alerts) else 0)'; then
    log 'PASS app healthy and TodoAppUnavailable cleared'; exit 0
  fi
  sleep 5
done
log 'FAIL recovery/alert clearing timed out'; exit 1
