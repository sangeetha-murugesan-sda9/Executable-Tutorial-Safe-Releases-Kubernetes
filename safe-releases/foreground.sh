#!/usr/bin/env bash
set -euo pipefail

while [ ! -f /tmp/tutorial-setup-done ]; do
  sleep 1
done

if grep -qx "ready" /tmp/tutorial-setup-status; then
  echo "Tutorial environment is ready. Continue to step 1."
else
  echo "Tutorial setup failed. Setup log:"
  cat /tmp/tutorial-setup.log
  exit 1
fi
