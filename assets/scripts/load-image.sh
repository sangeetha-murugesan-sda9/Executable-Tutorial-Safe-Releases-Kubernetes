#!/usr/bin/env bash
set -euo pipefail

image=${1:?usage: load-image.sh <image>}
engine=${CONTAINER_ENGINE:-}
if [ -z "$engine" ]; then
  if command -v docker >/dev/null 2>&1; then
    engine=docker
  elif command -v podman >/dev/null 2>&1; then
    engine=podman
  else
    echo "Install Docker or Podman, or set CONTAINER_ENGINE to an available builder." >&2
    exit 1
  fi
fi

case "$engine" in
  docker|podman) ;;
  *)
    echo "CONTAINER_ENGINE must be docker or podman." >&2
    exit 1
    ;;
esac

"$engine" image inspect "$image" >/dev/null

if [ "$(id -u)" -eq 0 ]; then
  "$engine" save "$image" | ctr -n k8s.io images import -
else
  "$engine" save "$image" | sudo ctr -n k8s.io images import -
fi
