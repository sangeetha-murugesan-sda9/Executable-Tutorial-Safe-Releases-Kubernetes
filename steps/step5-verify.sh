#!/usr/bin/env bash
set -euo pipefail

test "$(kubectl get deployment counter -o jsonpath='{.spec.template.spec.containers[0].image}')" = "counter:v2"
test "$(kubectl get deployment counter -o jsonpath='{.status.readyReplicas}')" = "3"
docker image inspect counter:v4 >/dev/null
