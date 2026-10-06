# 5. See what readiness checks miss

Version 4 can reach Redis, so `/healthz` passes. Its `/` route also tries to read a Redis key named `launched_at`; this tutorial never creates that key, so the route returns HTTP 500. Build v4 from its deliberately changed source:

```bash
cd ~/tutorial
bash assets/scripts/build-image.sh -t counter:v4 --build-arg APP_VERSION=v4 --build-arg APP_FILE=app_v4.py assets/app
bash assets/scripts/load-image.sh counter:v4
kubectl apply -f assets/manifests/counter-v4.yaml
kubectl rollout status deployment/counter --timeout=120s
```

The rollout succeeds. Compare the health check with the user-facing route:

```bash
curl -i http://127.0.0.1:30080/healthz
curl -i http://127.0.0.1:30080/
```

`/healthz` returns 200, while `/` returns 500. Readiness did exactly what it was configured to do; it did not test the app's main behavior.

Return to the known-good v2 before the capacity comparison:

```bash
kubectl rollout undo deployment/counter
kubectl rollout status deployment/counter --timeout=120s
```

Click **CHECK** when v2 is healthy and the v4 image is still available locally.
