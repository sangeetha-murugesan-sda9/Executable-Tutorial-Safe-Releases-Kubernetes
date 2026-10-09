#!/usr/bin/env bash
set -euo pipefail

test "$(kubectl get deployment counter -o jsonpath='{.status.readyReplicas}')" = "3"
test "$(kubectl get deployment redis -o jsonpath='{.status.readyReplicas}')" = "1"
kubectl get endpoints counter -o jsonpath='{.subsets[0].addresses[0].ip}' | grep -q .

# the traffic generator from the end of step 1 must be running
kill -0 "$(cat /tmp/traffic.pid)"