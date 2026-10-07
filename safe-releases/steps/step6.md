# 6. Compare rollout capacity

The last experiment uses the same unhealthy v3 release with two rolling-update policies. In one terminal, start the capacity sampler:

```bash
cd ~/tutorial
APP_URL=http://127.0.0.1:30080/ bash assets/scripts/traffic.sh start
bash assets/scripts/capacity.sh 45
```

While it runs, use a second terminal. Render the default-style policy (`fast`) and attempt the broken release:

```bash
cd ~/tutorial
fast=$(bash assets/scripts/render.sh v3 fast redis-cache)
bash assets/scripts/release.sh "$fast" 30s
```

The release helper should time out and roll back. After v2 is healthy again, run the sampler for the `safe` policy and repeat:

```bash
bash assets/scripts/capacity.sh 45
```

In the other terminal:

```bash
safe=$(bash assets/scripts/render.sh v3 safe redis-cache)
bash assets/scripts/release.sh "$safe" 30s
```

Both attempts fail because v3 cannot reach Redis. Compare the lowest `available` count printed by each sampler. The fast policy allows some unavailability; the safe policy sets `maxUnavailable: 0` and waits for a replacement to become ready before removing an old replica.

After both experiments, stop the traffic generator and inspect its results:

```bash
bash assets/scripts/traffic.sh summary
bash assets/scripts/traffic.sh stop
```

If `render.sh` reports that `envsubst` is missing, install it with `sudo apt-get update && sudo apt-get install -y gettext-base`, then retry. Click **CHECK** after the automatic rollback leaves v2 healthy.
