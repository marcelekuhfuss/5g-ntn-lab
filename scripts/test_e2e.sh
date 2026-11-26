#!/usr/bin/env bash
# End-to-end test: route traffic through the 5G link and measure it.
# Run after the UE has attached (srsUE prints "PDU Session Establishment successful").
set -euo pipefail

UE_IP="${UE_IP:-10.45.1.2}"
UPF_GW="10.45.1.1"
CORE_IP="10.53.1.2"

echo "== Routes =="
# Host -> UE subnet via the core container
sudo ip route replace 10.45.0.0/16 via "$CORE_IP"
# UE namespace default route via its TUN interface
sudo ip netns exec ue1 ip route replace default via "$UPF_GW" dev tun_srsue

echo "== Uplink ping (UE -> core) =="
sudo ip netns exec ue1 ping -c 5 "$UPF_GW"

echo "== Downlink ping (host -> UE) =="
ping -c 5 "$UE_IP"

if command -v iperf3 >/dev/null; then
  echo "== iperf3 downlink, 10 s (server in UE namespace) =="
  sudo ip netns exec ue1 iperf3 -s -1 -D
  sleep 1
  iperf3 -c "$UE_IP" -t 10 -b 20M || echo "iperf3 failed (check that the server started)"
else
  echo "iperf3 not installed — skipping throughput test (sudo apt install iperf3)"
fi

echo "OK: end-to-end 5G data path works."
