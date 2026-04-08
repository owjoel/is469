#!/bin/bash

set -u

MAX_RETRIES=3
MONITOR_INTERVAL=2

NAMES=("frontend" "loki" "tempo" "prometheus" "flagd" "chaos")
SERVICES=("frontend-proxy" "loki" "tempo" "prometheus" "flagd" "chaos-dashboard")
LOCAL_PORTS=(8080 3100 3200 9090 4000 2333)
REMOTE_PORTS=(8080 3100 3200 9090 4000 2333)
LOGS=("/tmp/proxy.log" "/tmp/loki.log" "/tmp/tempo.log" "/tmp/prom.log" "/tmp/flagd.log" "/tmp/chaos.log")

declare -A PIDS
declare -A FAILURES
SHUTTING_DOWN=0

cleanup() {
  SHUTTING_DOWN=1
  for name in "${NAMES[@]}"; do
    pid="${PIDS[$name]:-}"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done
}

handle_signal() {
  cleanup
  exit 0
}

trap cleanup EXIT
trap handle_signal INT TERM

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

start_forward() {
  local index="$1"
  local name="${NAMES[$index]}"
  local service="${SERVICES[$index]}"
  local local_port="${LOCAL_PORTS[$index]}"
  local remote_port="${REMOTE_PORTS[$index]}"
  local log_file="${LOGS[$index]}"

  kubectl port-forward -n otel-demo "svc/${service}" "${local_port}:${remote_port}" >"${log_file}" 2>&1 &
  PIDS["$name"]=$!
}

for i in "${!NAMES[@]}"; do
  FAILURES["${NAMES[$i]}"]=0
  start_forward "$i"
done

sleep 2

echo "Frontend:   http://localhost:8080"
echo "Loki:       http://localhost:3100"
echo "Tempo:      http://localhost:3200"
echo "Prometheus: http://localhost:9090"
echo "FlagD:      http://localhost:4000"
echo "ChaosMesh:  http://localhost:2333"

while true; do
  if (( SHUTTING_DOWN )); then
    exit 0
  fi

  for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"
    pid="${PIDS[$name]}"

    if ! kill -0 "$pid" 2>/dev/null; then
      FAILURES["$name"]=$((FAILURES["$name"] + 1))
      attempts="${FAILURES[$name]}"

      if (( attempts > MAX_RETRIES )); then
        echo "[$(timestamp)] Port-forward '${name}' failed more than ${MAX_RETRIES} times. Shutting down all forwards."
        exit 1
      fi

      echo "[$(timestamp)] Port-forward '${name}' stopped. Restart attempt ${attempts}/${MAX_RETRIES}."
      start_forward "$i"
    fi
  done

  sleep "${MONITOR_INTERVAL}"
done
