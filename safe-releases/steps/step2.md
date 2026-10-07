# 2. Release a healthy version 2

Build v2 from the same app source, load it into the Kubernetes node, then apply its manifest:

```bash
cd ~/tutorial
bash assets/scripts/build-image.sh -t counter:v2 --build-arg APP_VERSION=v2 assets/app
bash assets/scripts/load-image.sh counter:v2
kubectl apply -f assets/manifests/counter-v2.yaml
kubectl rollout status deployment/counter --timeout=120s
```

Check the app URL again. It should report `version=v2`, and `/` should continue returning HTTP 200 as the pods are replaced.

Click **CHECK** after all three replicas are v2 and ready.
