#!/usr/bin/env bash
set -euo pipefail

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

"$engine" build "$@"
