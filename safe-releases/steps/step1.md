# 1. Inspect the healthy baseline

The setup created Redis and released the v1 app. Check that Kubernetes has three ready app pods:

```bash
cd ~/tutorial
kubectl get deployments,pods,services
```

Open [the app on port 30080]({{TRAFFIC_HOST1_30080}}), or run:

```bash
curl http://127.0.0.1:30080/
curl http://127.0.0.1:30080/healthz
```

Refresh `/` a few times. The `hits` value should increase, even when different pods answer, because they all use the same Redis key.

Click **CHECK** when the counter deployment has three ready replicas.
