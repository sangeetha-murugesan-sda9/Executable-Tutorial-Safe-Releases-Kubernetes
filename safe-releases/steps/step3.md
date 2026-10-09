# 3. Watch v3 fail its readiness check

Version 3 intentionally points to `redis-cache`, but the Redis Service is named `redis`. The code is the same and the image builds fine, only the configuration doesn't match the environment. Unit tests would not catch this.

```
cd ~/tutorial
diff assets/manifests/counter-v2.yaml assets/manifests/counter-v3.yaml
```{{exec}}

Build and load the v3 app image, then apply the broken manifest. We clear the traffic log first again:

```
bash assets/scripts/build-image.sh -t counter:v3 --build-arg APP_VERSION=v3 assets/app
bash assets/scripts/load-image.sh counter:v3
bash assets/scripts/traffic.sh reset
kubectl apply -f assets/manifests/counter-v3.yaml
```{{exec}}

Wait for the rollout. It will not complete because the new pods cannot reach Redis:

```
kubectl rollout status deployment/counter --timeout=30s
kubectl get pods -l app=counter -L version
kubectl describe deployment counter
```{{exec}}

The rollout status command is expected to time out. There is one v3 pod that is Running but `0/1` Ready, and the three v2 pods are still there. Kubernetes won't remove a v2 pod before a v3 pod is available, and that will never happen. The old v2 pods should still serve requests:

```
curl http://127.0.0.1:30080/
```{{exec}}

## Why is it stuck?

The events of the v3 pod show what the readiness probe saw:

```
kubectl describe pod -l version=v3 | sed -n '/Events:/,$p'
```{{exec}}

You see `Readiness probe failed`. Depending on timing it says `statuscode: 503` (the app answered that Redis is unreachable) or `context deadline exceeded` (looking up the missing service took longer than the 1 second probe timeout). Both mean the pod is not Ready and gets no traffic.

Inspect the mismatch:

```
kubectl get service redis
kubectl get service redis-cache
```{{exec}}

`redis` exists, `redis-cache` doesn't. After 60 seconds without progress, Kubernetes also marks the rollout as failed:

```
until kubectl get deployment counter -o jsonpath='{.status.conditions[?(@.type=="Progressing")].reason}' | grep -q ProgressDeadlineExceeded; do sleep 2; done
kubectl get deployment counter -o jsonpath='{range .status.conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
```{{exec}}

This waits until the 60 seconds are over, then you see `Progressing=False (ProgressDeadlineExceeded)`. Note that Kubernetes does not roll back by itself. The broken pod just stays there until someone does something.

What did the users see?

```
bash assets/scripts/traffic.sh summary
```{{exec}}

Only v2 and only HTTP 200. The v3 pod was never Ready, so it never got any traffic. The readiness probe turned a broken release into a stuck one.

## Undo the release

```
kubectl rollout undo deployment/counter
kubectl rollout status deployment/counter --timeout=120s
kubectl get pods -l app=counter -L version
```{{exec}}

The v3 pod is gone and v2 serves all requests again.

Click **CHECK** after v2 is serving again.