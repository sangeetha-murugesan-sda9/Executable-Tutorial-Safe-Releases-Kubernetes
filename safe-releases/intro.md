# Safe Releases with Progressive Delivery

In this lab, you will release several versions of a small Flask app backed by Redis. You will see what Kubernetes readiness checks protect, how a failed rollout can be rolled back, and how rollout settings affect available capacity.

The one-node Kubernetes cluster and the healthy v1 baseline are prepared automatically. Wait for the terminal to say **Tutorial environment is ready** before starting.

The app has three replicas behind a Kubernetes Service. Open the app at [port 30080]({{TRAFFIC_HOST1_30080}}). Each request to `/` increments a shared Redis counter; `/healthz` checks Redis.

All files are available in `~/tutorial`. The lab builds local images and imports them into the node's containerd image store; no Docker Hub account or registry is needed.

> This lab is disposable. Do not put secrets or production data in it.
