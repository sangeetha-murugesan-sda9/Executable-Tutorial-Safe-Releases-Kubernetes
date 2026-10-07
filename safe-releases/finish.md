# Lab complete

You saw three important limits and controls:

- A readiness probe keeps pods that fail the probe out of Service traffic, but it only checks the condition you configure.
- A rollout timeout plus rollback can restore the previous Deployment revision automatically.
- `maxUnavailable: 0` protects the number of available old replicas during an update, at the cost of waiting for an extra pod to become ready.

The v4 app returned HTTP 500 from `/` even though `/healthz` succeeded. A production rollout usually needs more than readiness probes: canary or blue-green delivery can evaluate user-facing metrics and stop a release when behavior degrades.

The environment is temporary and will be removed when the Killercoda session ends.
