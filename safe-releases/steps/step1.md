# 1. Inspect the healthy baseline

The setup created Redis and released the v1 app. Check that Kubernetes has three ready app pods:

```
cd ~/tutorial
kubectl get deployments,pods,services
```{{exec}}

## The app

```
cat assets/app/app.py
```{{exec}}

Two things are important for later. `/healthz` only checks if the pod can reach Redis, and Kubernetes will fully trust that answer. Also, every response (even an error) contains `version=...`, so we can always see which version answered.

## The Deployment

```
cat assets/manifests/counter-v1.yaml
```{{exec}}

These settings make the release safer:

- `readinessProbe` on `/healthz` (every 2s, 2 failures allowed): a pod only gets traffic when it is Ready, and during a rollout an old pod is only removed when a new one is Ready.
- `minReadySeconds: 5`: a new pod has to stay Ready for 5 seconds before it counts. This catches pods that start and crash right after.
- `progressDeadlineSeconds: 60`: if the rollout doesn't move for 60 seconds, Kubernetes marks it as failed.
- `maxSurge` and `maxUnavailable` (25% each): the Kubernetes defaults, we come back to them in step 6.
- `preStop: sleep 5`: a pod that is shutting down keeps serving for 5 more seconds while it is removed from the Service, so requests don't hit a closed port.
- `imagePullPolicy: Never`: the images are built here in the lab and never downloaded.

We did not add a liveness probe on `/healthz` on purpose. A liveness probe restarts the container when it fails. If Redis went down, Kubernetes would keep restarting all app pods, which doesn't fix Redis and only causes more load.

## Try it

Open [the app on port 30080]({{TRAFFIC_HOST1_30080}}), or run:

```
curl http://127.0.0.1:30080/
curl http://127.0.0.1:30080/healthz
```{{exec}}

Refresh `/` a few times. The `hits` value should increase, even when different pods answer, because they all use the same Redis key. You can also call it a few times in a row:

```
for i in 1 2 3 4 5 6; do curl -s http://127.0.0.1:30080/; done
```{{exec}}

That is what makes a rolling update possible: any pod, old or new, can answer any request.

## Start the users

```
export APP_URL=http://127.0.0.1:30080
bash assets/scripts/traffic.sh start
sleep 5; bash assets/scripts/traffic.sh summary
```{{exec}}

The traffic script now runs in the background until the end of the lab. Before each release we clear its log with `traffic.sh reset`, and after the release `traffic.sh summary` tells us what the users got.

Click **CHECK** when the counter deployment has three ready replicas and the traffic script is running.
