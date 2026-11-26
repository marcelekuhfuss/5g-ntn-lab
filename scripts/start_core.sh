#!/usr/bin/env bash
# Start the Open5GS 5G core in Docker, using the setup shipped with OCUDU (ocudu/docker).
# Expects OCUDU cloned at $OCUDU_DIR (default: ~/src/ocudu).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OCUDU_DIR="${OCUDU_DIR:-$HOME/src/ocudu}"
DOCKER_DIR="$OCUDU_DIR/docker"

if [[ ! -d "$DOCKER_DIR/open5gs" ]]; then
  echo "OCUDU docker folder not found at $DOCKER_DIR" >&2
  echo "Set OCUDU_DIR or clone OCUDU first (see docs/stage1_setup.md)." >&2
  exit 1
fi

# Use our subscriber list instead of the default one.
cp "$REPO_DIR/configs/subscriber_db.csv" "$DOCKER_DIR/open5gs/subscriber_db.csv"

cd "$DOCKER_DIR"
echo "Starting Open5GS core (service 5gc) — AMF at 10.53.1.2 ..."
docker compose up --build 5gc
