#!/usr/bin/env bash
set -Eeuo pipefail

work="$HOME/tutorial"
log=/tmp/tutorial-setup.log
done_file=/tmp/tutorial-setup-done
status_file=/tmp/tutorial-setup-status

exec >"$log" 2>&1
trap 'status=$?; printf "failed (%s)\n" "$status" > "$status_file"; touch "$done_file"; exit "$status"' ERR

echo "Waiting for the Kubernetes node..."
for attempt in $(seq 1 90); do
  if kubectl get nodes >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl get nodes

echo "Building and loading the v1 application image..."
bash "$work/assets/scripts/build-image.sh" -t counter:v1 --build-arg APP_VERSION=v1 "$work/assets/app"
bash "$work/assets/scripts/load-image.sh" counter:v1

echo "Starting Redis and the v1 application..."
kubectl apply -f "$work/assets/manifests/redis.yaml"
kubectl rollout status deployment/redis --timeout=180s
kubectl apply -f "$work/assets/manifests/counter-v1.yaml"
kubectl rollout status deployment/counter --timeout=180s

printf "ready\n" > "$status_file"
touch "$done_file"
