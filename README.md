# Safe Releases with Progressive Delivery

Executable tutorial for the DevOps course (Continuous Delivery).

Run it here: https://killercoda.com/kth-safe-releases/scenario/safe-releases

You don't need an account, everything runs in the browser.

This repository is a single Killercoda Kubernetes scenario. Its `index.json` is in the `safe-releases/` folder (Killercoda only finds scenarios inside a folder). The scenario prepares a one-node cluster with Redis and the v1 counter app, then guides learners through healthy and failing releases, rollback, readiness-probe limitations, and rollout capacity.

## What it is about

A small Flask app that counts visits in Redis runs with 3 replicas on Kubernetes. We release a few versions and check what the users actually get during each release:

1. v1 is already running, we look at the setup and start a script that plays the users
2. v2 works: normal rolling update, no failed requests
3. v3 points to a Redis service that doesn't exist: the readiness probe fails, the rollout gets stuck, users never see it. We roll back by hand.
4. same v3, but `release.sh` notices the timeout and rolls back by itself
5. v4 has a bug in `/` but `/healthz` is fine: the rollout succeeds and users get 500s. A smoke test catches it, but late.
6. the same broken v3 with `maxUnavailable: 25%` (default) and `0`: speed vs. capacity

The finish page has our reflection: what readiness checks can and can't catch, when a rolling update is enough, and when you need canary or blue-green releases.

## Structure

```
safe-releases/            the Killercoda scenario
  index.json              steps, setup scripts, files to copy
  background.sh           waits for the node, builds v1, deploys redis + v1
  foreground.sh           waits until the setup is done
  intro.md, finish.md
  steps/                  stepN.md and stepN-verify.sh (CHECK button)
  assets/
    app/                  app.py (v1-v3), app_v4.py, Dockerfile
    manifests/            redis, counter-v1 to v4, template for step 6
    scripts/              build/load image, traffic, release, render, capacity
    figures/              diagrams used in the text
```

Killercoda copies `app`, `manifests` and `scripts` to `~/tutorial/assets/` on the lab machine.

The scenario uses Killercoda's `kubernetes-kubeadm-1node` environment. It builds the app image inside the lab with Docker (or Podman if Docker is unavailable) and imports it into the Kubernetes node, so learners do not need a local cluster or Docker Hub account.

## Scripts

- `build-image.sh` / `load-image.sh`: build the image and import it into containerd on the node
- `traffic.sh start|reset|summary|live|stop`: fake users, ~5 requests per second, logs status code and version of each answer
- `release.sh <manifest> [timeout]`: apply, wait, roll back if it doesn't finish in time. With `SMOKE_URL` it also tests the app afterwards. Every result goes to `/tmp/releases.log`.
- `render.sh <version> <fast|safe> [redis host]`: fills in the template for step 6 (4 replicas)
- `capacity.sh [seconds]`: how many pods are available, every second

## Publish and open it on Killercoda

1. Push this repository and branch to GitHub.
2. Sign in to Killercoda and open the [Creator Repository page](https://killercoda.com/creator/repository).
3. Add `sangeetha-murugesan-sda9/Executable-Tutorial-Safe-Releases-Kubernetes` and the branch to use (`main`). Only the name, without `https://github.com/`, otherwise the webhook fails with "github repo name not matching webhook repo name".
4. Grant Killercoda read access using the deploy key shown on that page, then add the GitHub webhook using the payload URL and secret Killercoda provides.
5. Open the [Creator Scenarios page](https://killercoda.com/creator/scenarios), launch **Safe Releases with Progressive Delivery**, and wait for the setup terminal to say it is ready.

After that, every push to `main` updates the scenario.

## Validate changes

The scenario configuration is `index.json`; learner instructions are in `intro.md`, `steps/`, and `finish.md`. `background.sh` prepares the initial v1 deployment, and each `steps/*-verify.sh` backs a Killercoda **CHECK** button.

Before pushing edits, validate the JSON and shell syntax (from the `safe-releases/` folder):

```bash
cd safe-releases
jq -e . index.json >/dev/null
for file in background.sh foreground.sh assets/scripts/*.sh steps/*-verify.sh; do
  bash -n "$file"
done
```

The `.sh` files need LF line endings, `.gitattributes` takes care of that.

The full setup and release flow must be tested in Killercoda because its Kubernetes node and container runtime are provided by the platform. We tested the app and the manifests locally first with Docker Desktop.

Free Killercoda accounts can only run one lab at a time. When testing, close a lab with the Exit button instead of just closing the tab, otherwise you have to wait a few minutes before the next one starts.

## Authors

- Sangeetha Murugesan
- Ziyad Derghazi
