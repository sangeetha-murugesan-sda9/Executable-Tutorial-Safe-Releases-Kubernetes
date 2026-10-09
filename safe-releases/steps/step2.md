# 2. Release a healthy version 2

Now we replace all pods with a new version and check that the users don't notice.

What is different between v1 and v2?

```
cd ~/tutorial
diff assets/manifests/counter-v1.yaml assets/manifests/counter-v2.yaml
```{{exec}}

Only the image, the `version` label and the change note. Any change in the pod template creates a new ReplicaSet and starts a rollout.

Build v2 from the same app source, load it into the Kubernetes node, then apply its manifest. We also clear the traffic log first, so we only count what happens during this release:

```
bash assets/scripts/build-image.sh -t counter:v2 --build-arg APP_VERSION=v2 assets/app
bash assets/scripts/load-image.sh counter:v2
bash assets/scripts/traffic.sh reset
kubectl apply -f assets/manifests/counter-v2.yaml
kubectl rollout status deployment/counter --timeout=120s
```{{exec}}

![Rolling update](../assets/figures/rolling-update.png)

Check the app URL again. It should report `version=v2`, and `/` should continue returning HTTP 200 as the pods are replaced. The traffic script shows what the users got during the release:

```
bash assets/scripts/traffic.sh summary
```{{exec}}

There should be answers from v1 and v2, all with HTTP 200, and 0 failed requests.

## Why nothing failed

Three things work together here:

1. A new pod is only added to the Service after `/healthz` succeeds.
2. With 3 replicas, `maxUnavailable: 25%` is rounded down to 0 and `maxSurge: 25%` is rounded up to 1. So Kubernetes first adds one new pod and only removes an old one when the new pod has been available for `minReadySeconds`.
3. An old pod is first taken out of the Service, keeps serving for 5 seconds (`preStop`), and then gunicorn finishes the open requests.

```
kubectl get replicasets -l app=counter -L version
kubectl rollout history deployment/counter
```{{exec}}

The old ReplicaSet is scaled down to 0 but it is kept. That is what `rollout undo` uses in the next step.

One thing to keep in mind: during every rollout, two versions are serving users at the same time. So a new version has to stay compatible with the old one (same API, same data in Redis). That is also why database changes are usually split into several small releases.

Click **CHECK** after all three replicas are v2 and ready.
