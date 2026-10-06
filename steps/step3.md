# 3. Watch v3 fail its readiness check

Version 3 intentionally points to `redis-cache`, but the Redis Service is named `redis`. Build and load the v3 app image, then apply the broken manifest:

```bash
cd ~/tutorial
bash assets/scripts/build-image.sh -t counter:v3 --build-arg APP_VERSION=v3 assets/app
bash assets/scripts/load-image.sh counter:v3
kubectl apply -f assets/manifests/counter-v3.yaml
```

Wait for the rollout. It will not complete because the new pods cannot reach Redis:

```bash
kubectl rollout status deployment/counter --timeout=30s
kubectl get pods -l app=counter -L version
kubectl describe deployment counter
```

The rollout status command is expected to time out. The old v2 pods should still serve requests:

```bash
curl http://127.0.0.1:30080/
```

Inspect the mismatch and undo the release:

```bash
kubectl get service redis
kubectl rollout undo deployment/counter
kubectl rollout status deployment/counter --timeout=120s
```

Click **CHECK** after v2 is serving again.
