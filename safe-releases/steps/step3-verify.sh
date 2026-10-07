#!/usr/bin/env bash
set -euo pipefail

test "$(kubectl get deployment counter -o jsonpath='{.spec.template.spec.containers[0].image}')" = "counter:v2"
test "$(kubectl get deployment counter -o jsonpath='{.status.readyReplicas}')" = "3"
test "$(curl -fsS --max-time 3 http://127.0.0.1:30080/ | grep -c 'version=v2')" -eq 1
