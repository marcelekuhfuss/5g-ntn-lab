#!/usr/bin/env bash
# Run the OCUDU gNB with the ZMQ virtual radio. Start the core first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GNB_BIN="${GNB_BIN:-$(command -v gnb || echo "${OCUDU_DIR:-$HOME/src/ocudu}/build/apps/gnb/gnb")}"

sudo "$GNB_BIN" -c "$REPO_DIR/configs/gnb_zmq.yaml"
