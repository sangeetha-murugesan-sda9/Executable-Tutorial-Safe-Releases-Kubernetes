# Safe Releases with Progressive Delivery

This repository is a single Killercoda Kubernetes scenario. Its `index.json` is at the repository root. The scenario prepares a one-node cluster with Redis and the v1 counter app, then guides learners through healthy and failing releases, rollback, readiness-probe limitations, and rollout capacity.

## Publish and open it on Killercoda

1. Push this repository and branch to GitHub.
2. Sign in to Killercoda and open the [Creator Repository page](https://killercoda.com/creator/repository).
3. Add `sangeetha-murugesan-sda9/Executable-Tutorial-Safe-Releases-Kubernetes` and the branch to use.
4. Grant Killercoda read access using the deploy key shown on that page, then add the GitHub webhook using the payload URL and secret Killercoda provides.
5. Open the [Creator Scenarios page](https://killercoda.com/creator/scenarios), launch **Safe Releases with Progressive Delivery**, and wait for the setup terminal to say it is ready.

The scenario uses Killercoda's `kubernetes-kubeadm-1node` environment. It builds the app image inside the lab with Docker (or Podman if Docker is unavailable) and imports it into the Kubernetes node, so learners do not need a local cluster or Docker Hub account.

## Validate changes

The scenario configuration is `index.json`; learner instructions are in `intro.md`, `steps/`, and `finish.md`. `background.sh` prepares the initial v1 deployment, and each `steps/*-verify.sh` backs a Killercoda **CHECK** button.

Before pushing edits, validate the JSON and shell syntax:

```bash
jq -e . index.json >/dev/null
for file in background.sh foreground.sh assets/scripts/*.sh steps/*-verify.sh; do
  bash -n "$file"
done
```

The full setup and release flow must be tested in Killercoda because its Kubernetes node and container runtime are provided by the platform.
