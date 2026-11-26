#!/usr/bin/env bash
# Run srsUE (5G SA, ZMQ) inside network namespace ue1. Start the gNB first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UE_BIN="${UE_BIN:-$(command -v srsue || echo "$HOME/src/srsRAN_4G/build/srsue/src/srsue")}"

# The UE's TUN interface lives in its own namespace so its traffic really
# goes through the 5G link instead of the host's normal routing.
if ! ip netns list | grep -qw ue1; then
  sudo ip netns add ue1
fi

sudo "$UE_BIN" "$REPO_DIR/configs/ue_zmq.conf"
