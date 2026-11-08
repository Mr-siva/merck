#!/usr/bin/env bash
# Probe /health; after RETRIES failures restart the service and log to the journal.
set -euo pipefail

URL="${HEALTH_URL:-http://127.0.0.1:80/health}"
SERVICE="${SERVICE_NAME:-hello.service}"
RETRIES="${RETRIES:-3}"
SLEEP="${RETRY_SLEEP:-2}"

for ((i = 1; i <= RETRIES; i++)); do
  if curl -fsS --max-time 3 "$URL" >/dev/null 2>&1; then
    exit 0
  fi
  sleep "$SLEEP"
done

logger -t healthcheck -p user.err "health check failed ${RETRIES}x for ${URL}; restarting ${SERVICE}"
if ! systemctl restart "$SERVICE"; then
  logger -t healthcheck -p user.crit "restart of ${SERVICE} FAILED"
  exit 2
fi
logger -t healthcheck "restarted ${SERVICE}"
exit 1
