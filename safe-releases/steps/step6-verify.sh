#!/usr/bin/env bash
set -euo pipefail

test "$(kubectl get deployment counter -o jsonpath='{.spec.template.spec.containers[0].image}')" = "counter:v2"
# step 6 runs with 4 replicas, so compare with what the deployment wants
want=$(kubectl get deployment counter -o jsonpath='{.spec.replicas}')
test "$(kubectl get deployment counter -o jsonpath='{.status.readyReplicas}')" = "$want"
# both broken releases were rolled back by the script
grep -q "counter-v3-fast.yaml result=ROLLED_BACK" /tmp/releases.log
grep -q "counter-v3-safe.yaml result=ROLLED_BACK" /tmp/releases.log