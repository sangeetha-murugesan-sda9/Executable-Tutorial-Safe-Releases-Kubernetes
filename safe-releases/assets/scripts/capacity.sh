#!/usr/bin/env bash
# capacity.sh [seconds] - how many counter pods can take traffic, sampled every second
secs=${1:-30}
want=$(kubectl get deploy counter -o jsonpath='{.spec.replicas}')
lowest=$want

for t in $(seq 1 $secs); do
  read avail total < <(kubectl get deploy counter -o go-template='{{or .status.availableReplicas 0}} {{.status.replicas}}')
  notready=$(kubectl get pods -l app=counter --no-headers | grep -c ' 0/1 ')
  [ $avail -lt $lowest ] && lowest=$avail
  echo "${t}s  available=$avail/$want  pods=$total  not ready=$notready"
  sleep 1
done

echo "lowest: $lowest/$want"