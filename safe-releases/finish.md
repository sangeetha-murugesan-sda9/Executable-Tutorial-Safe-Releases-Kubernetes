# Lab complete

You saw three important limits and controls:

- A readiness probe keeps pods that fail the probe out of Service traffic, but it only checks the condition you configure.
- A rollout timeout plus rollback can restore the previous Deployment revision automatically.
- `maxUnavailable: 0` protects the number of available old replicas during an update, at the cost of waiting for an extra pod to become ready.

The v4 app returned HTTP 500 from `/` even though `/healthz` succeeded. A production rollout usually needs more than readiness probes: canary or blue-green delivery can evaluate user-facing metrics and stop a release when behavior degrades.

## What happened in our runs

- v2 replaced all pods and the traffic script counted 0 failed requests.
- v3 never became Ready, so users only ever got v2. Kubernetes marked the rollout as failed after 60 seconds but didn't roll it back. In step 4 our script did that.
- v4 passed every health check, the rollout "succeeded", and users got HTTP 500. The smoke test caught it, but only after everyone was already on v4.
- With 4 replicas, the default settings dropped to 3 of 4 available pods during the broken release, `maxUnavailable: 0` stayed at 4 of 4. No requests failed in either case.

## What readiness probes catch and what they don't

They catch things that stop a pod from doing its basic job: wrong config, a missing dependency, wrong credentials, a crash at startup, a wrong port. In all of these the pod never becomes Ready.

They don't catch bugs in features (like v4), answers that are wrong but look fine, slowness or memory leaks that only show up under real load, or problems that only some users have. A probe tells you if one pod can serve, not if the release is good. And making the probe check more is not the fix, as we saw in step 5, it can turn a small problem into a full outage.

## When is a rolling update enough?

We think a rolling update with readiness probes and an automatic rollback is fine when:

- the team is small, the service is internal or doesn't have much traffic, and a few minutes of errors for some users is acceptable,
- most broken releases are config or dependency problems,
- there are good tests before the release, so feature bugs rarely get to production,
- a team is just starting with Continuous Delivery. It's built into Kubernetes and needs no extra tools.

It's not enough when a bad release is expensive, for example with lots of users, payments or strict SLAs. A rolling update can't limit how many users get the new version, and it decides based on pod health instead of what users experience. Then teams usually use:

- **Canary releases with metrics.** A small part of the traffic (say 5%, then 25%, then 50%) goes to the new version, and an automatic check compares its error rate and latency with the old version. If it's worse, it stops. Argo Rollouts and Flagger do this, together with a service mesh or ingress controller to split the traffic. v4 would have been stopped at around 5% of users instead of 100%.
- **Blue-green releases.** The new version runs fully next to the old one, gets tested, and then all traffic switches at once. Rolling back means switching back. It needs double the resources during the release, but works when two versions can't run at the same time.
- **Feature flags**, where the code is deployed but the feature is switched on separately. The v4 feature could have just been turned off.

These also cost something. You need metrics you can trust, enough traffic for the comparison to mean anything (5% of 10 requests a minute tells you nothing), and more things to run. So our answer to "for whom": rolling updates are a good default for most teams, canary analysis pays off for big and important services, and blue-green is for systems that need a clean switch.

## Why we built it like this

| Decision | Why |
|---|---|
| Plain Deployment with a readiness probe | It's built into Kubernetes, and the bigger tools use the same ideas. Starting with Argo Rollouts would hide the basics. |
| Killercoda `kubernetes-kubeadm-1node` | A real Kubernetes node in the browser, nobody needs an account or a cloud. |
| Building the images inside the lab | No registry or Docker Hub account needed. |
| Keeping the state in Redis | Two versions can run side by side, and the health check has something real to check. |
| `/healthz` checks Redis, no liveness probe | Readiness should mean "can serve". Restarting pods doesn't fix a missing Redis, it just causes restart loops. |
| `minReadySeconds`, `preStop` and gunicorn | No pods that pass once and then crash, and no lost requests when a pod shuts down. |
| The release logic is a small bash script | Easy to read and easy to put into any CI/CD pipeline. |
| Rolling back to a saved revision | Still correct if the manifest didn't change anything. |
| A traffic script with a summary | Shows what users actually got, not only what Kubernetes says. |

## Limits of this lab

Everything runs on one node, so things like scheduling, node failures or a full cluster don't show up. The traffic is small and comes from a script. The release script rolls back the cluster but not Git. Redis has no persistence and only one instance. None of this changes the main points, but in a real setup all of it matters.

The environment is temporary and will be removed when the Killercoda session ends.