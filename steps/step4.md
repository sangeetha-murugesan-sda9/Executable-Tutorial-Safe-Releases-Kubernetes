# 4. Automate rollback for the same failure

The v3 image is already loaded. Use the release helper to apply the same broken manifest, wait up to 30 seconds, and automatically undo the change if the rollout does not finish:

```bash
cd ~/tutorial
bash assets/scripts/release.sh assets/manifests/counter-v3.yaml 30s
```

The script exits with a failure status after rolling back. That is expected: the release failed, but the running app should be back on v2.

```bash
kubectl get deployment counter
curl http://127.0.0.1:30080/
```

Click **CHECK** once the deployment has three ready v2 replicas again.
