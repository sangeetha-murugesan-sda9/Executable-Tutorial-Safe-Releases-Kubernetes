#!/usr/bin/env bash
# release.sh <manifest> [timeout]
# applies the manifest, waits for the rollout and rolls back if it doesn't finish in time.
# set SMOKE_URL to also check that the app answers 200 after the rollout.

set -uo pipefail

manifest=${1:?usage: release.sh <manifest> [timeout]}
timeout=${2:-90s}
deploy=${DEPLOY:-counter}
smoke_url=${SMOKE_URL:-}

say() { echo "[release $(date +%T)] $*"; }
record() { echo "$(date -Is) $deploy $manifest result=$1" >> /tmp/releases.log; }
current_rev() {
  kubectl get deploy "$deploy" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}' 2>/dev/null
}

rollback() {
  if [ -z "$prev" ]; then
    say "first release, nothing to roll back to"
    record FAILED
    exit 1
  fi
  say "rolling back to revision $prev"
  kubectl rollout undo deploy/"$deploy" --to-revision="$prev"
  if kubectl rollout status deploy/"$deploy" --timeout="$timeout"; then
    say "rollback done"
    record "$1"
  else
    say "rollback got stuck too, someone needs to look at this"
    record ROLLBACK_FAILED
  fi
  exit 1
}

smoke_test() {
  fails=0
  for i in $(seq 20); do
    code=$(curl -s -o /dev/null -m 2 -w '%{http_code}' "$smoke_url")
    [ "$code" = 200 ] || fails=$((fails + 1))
    sleep 0.1
  done
  say "smoke test: $fails/20 requests failed"
  [ $fails -eq 0 ]
}


prev=$(current_rev)
say "$deploy is at revision ${prev:-none}, applying $manifest"
kubectl apply -f "$manifest" || { record APPLY_FAILED; exit 2; }

if ! kubectl rollout status deploy/"$deploy" --timeout="$timeout"; then
  say "rollout not done after $timeout"
  # grab what we can before the rollback removes the broken pods
  kubectl get pods -l app="$deploy" -L version
  kubectl get deploy "$deploy" -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
  kubectl get events --field-selector reason=Unhealthy --sort-by=.lastTimestamp | tail -3
  rollback ROLLED_BACK
fi

if [ -n "$smoke_url" ] && ! smoke_test; then
  if [ "$(current_rev)" = "$prev" ]; then
    say "smoke test failed but nothing was changed, not rolling back"
    record SMOKE_FAILED
    exit 1
  fi
  rollback SMOKE_FAILED_ROLLED_BACK
fi

say "SUCCESS, $deploy is at revision $(current_rev)"
record SUCCESS