# 5. See what readiness checks miss

Version 4 can reach Redis, so `/healthz` passes. Its `/` route also tries to read a Redis key named `launched_at`; this tutorial never creates that key, so the route returns HTTP 500. Here is what changed in the code:

```
cd ~/tutorial
diff assets/app/app.py assets/app/app_v4.py
```{{exec}}

v4 shows "hits per minute". For that it needs `launched_at`, which a migration job was supposed to create. Nobody ran the job, so `float(None)` crashes on every request to `/`. The `/healthz` part is the same as before.

Build v4 from its deliberately changed source (and clear the traffic log again):

```
bash assets/scripts/build-image.sh -t counter:v4 --build-arg APP_VERSION=v4 --build-arg APP_FILE=app_v4.py assets/app
bash assets/scripts/load-image.sh counter:v4
bash assets/scripts/traffic.sh reset
kubectl apply -f assets/manifests/counter-v4.yaml
kubectl rollout status deployment/counter --timeout=120s
```{{exec}}

The rollout succeeds. Compare the health check with the user-facing route:

```
curl -i http://127.0.0.1:30080/healthz
curl -i http://127.0.0.1:30080/
```{{exec}}

`/healthz` returns 200, while `/` returns 500. Readiness did exactly what it was configured to do; it did not test the app's main behavior.

So what did our users get?

```
bash assets/scripts/traffic.sh summary
kubectl logs -l version=v4 --tail=5
```{{exec}}

Lots of 500s from v4, and the log shows the `TypeError`. Kubernetes said everything was fine the whole time.

## Why didn't the probe catch it?

The probe only asks "can this pod reach Redis?". v3 couldn't, v4 can. That's all it knows.

We could probe `/` instead, but that's a bad idea:

- `/` increments the counter, so every probe would change data.
- If the probe checks everything, one small problem (for example Redis being slow for a moment) makes all pods unready at once. Then the Service has no pods left and the whole app is down.
- Probes run every 2 seconds on every pod, so they should be cheap.

Checking that a feature actually works is the job of tests before the release and of checks during and after it.

Return to the known-good v2:

```
kubectl rollout undo deployment/counter
kubectl rollout status deployment/counter --timeout=120s
```{{exec}}

## Adding a smoke test

Our `release.sh` can also test the app after the rollout. If `SMOKE_URL` is set, it sends 20 requests, and if any of them fails it rolls back. Let's try v4 again with that:

```
bash assets/scripts/traffic.sh reset
SMOKE_URL=http://127.0.0.1:30080/ bash assets/scripts/release.sh assets/manifests/counter-v4.yaml; echo "exit code: $?"
```{{exec}}

```
tail -2 /tmp/releases.log
bash assets/scripts/traffic.sh summary
```{{exec}}

This time the script notices and rolls back (`SMOKE_FAILED_ROLLED_BACK`). But look at the summary: users still got errors. The smoke test only runs after the rollout is finished, and by then everyone is already on v4.

That's the real limit of a rolling update. It decides based on pod health, not on what users see. To catch v4 early you'd send only a small part of the traffic to it, watch the error rate, and stop if it gets worse than before. That's called a canary release, more about it at the end.

Click **CHECK** when v2 is healthy and the v4 image is still available locally.
