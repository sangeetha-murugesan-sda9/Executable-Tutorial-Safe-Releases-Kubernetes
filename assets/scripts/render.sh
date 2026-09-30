#!/usr/bin/env bash
# render.sh <version> <fast|safe> [redis host]
# fills in manifests/counter-template.yaml, prints the path of the result
set -e

export VERSION=$1 STRATEGY=$2 REDIS_HOST=${3:-redis} REPLICAS=4

if [ "$STRATEGY" = fast ]; then
  export MAX_SURGE=25% MAX_UNAVAILABLE=25%   # k8s default
elif [ "$STRATEGY" = safe ]; then
  export MAX_SURGE=1 MAX_UNAVAILABLE=0
else
  echo "usage: render.sh <version> <fast|safe> [redis host]" >&2
  exit 1
fi

dir=$(dirname "$0")
out=/tmp/counter-$VERSION-$STRATEGY.yaml
envsubst < "$dir/../manifests/counter-template.yaml" > "$out"
echo "$out"