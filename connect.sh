#!/bin/bash
trap 'kill 0' EXIT

kubectl port-forward -n otel-demo svc/frontend-proxy 8080:8080 > /tmp/proxy.log 2>&1 &
kubectl port-forward -n otel-demo svc/loki 3100:3100 > /tmp/loki.log 2>&1 &
kubectl port-forward -n otel-demo svc/tempo 3200:3200 > /tmp/tempo.log 2>&1 &
kubectl port-forward -n otel-demo svc/prometheus 9090:9090 > /tmp/prom.log 2>&1 &

sleep 2

echo "Frontend:   http://localhost:8080"
echo "Loki:       http://localhost:3100"
echo "Tempo:      http://localhost:3200"
echo "Prometheus: http://localhost:9090"

wait