#!/usr/bin/env bash
set -euo pipefail

test "$(kubectl get deployment counter -o jsonpath='{.spec.template.spec.containers[0].image}')" = "counter:v2"
test "$(kubectl get deployment counter -o jsonpath='{.status.readyReplicas}')" = "3"
docker image inspect counter:v4 >/dev/null
# the smoke test should have rolled v4 back
grep -q "counter-v4.yaml result=SMOKE_FAILED_ROLLED_BACK" /tmp/releases.log