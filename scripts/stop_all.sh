#!/usr/bin/env bash
# Stop UE, gNB and core, and clean up the UE namespace.
set -uo pipefail

OCUDU_DIR="${OCUDU_DIR:-$HOME/src/ocudu}"

sudo pkill -INT srsue || true
sudo pkill -INT gnb || true
(cd "$OCUDU_DIR/docker" && docker compose down) || true
sudo ip netns delete ue1 2>/dev/null || true
echo "Stopped."
