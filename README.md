# 5G NTN Lab — a software-only 5G SA testbed with jamming emulation and an AI xApp

An open-source, fully software-defined 5G Standalone network running on a single Linux PC:
**Open5GS** core + **OCUDU** gNB (Linux Foundation, successor of srsRAN Project) + **srsUE**, linked through a virtual radio (ZeroMQ IQ samples).
A **GNU Radio** channel broker sits between UE and gNB to inject noise, fading, Doppler, NTN delay
and **jammers**, and an **O-RAN xApp** (FlexRIC) detects and reacts to interference with an ML model.

No RF hardware is required: every IQ sample is exchanged in software, so all tests are legal,
reproducible, and runnable in CI.

```
 srsUE ──ZMQ IQ──► [GNU Radio: channel + jammer] ──ZMQ IQ──► OCUDU gNB ──N2/N3──► Open5GS core
                                                                  │
                                                        E2 ──► FlexRIC + AI xApp
                                                                  │
                                                       Prometheus / Grafana dashboards
```

## Status

| Stage | Milestone | Status |
|---|---|---|
| 1 | Core (Docker) + gNB + srsUE over ZMQ, end-to-end ping and iperf3 | 🚧 in progress |
| 2 | GNU Radio broker: AWGN, fading, Doppler, configurable jammers | ⬜ |
| 3 | KPI monitoring (SINR, BLER, throughput, HARQ) in Grafana, clean vs. jammed | ⬜ |
| 4 | FlexRIC + ML anti-jamming xApp reacting to interference | ⬜ |
| 5 | NTN profiles: LEO/GEO delay and Doppler (OCUDU 26.10 Rel-17 NTN support) | ⬜ |
| 6 | Full containerisation + GitHub Actions end-to-end test on every commit | ⬜ |

## Quick start (stage 1)

Requirements: Ubuntu 22.04 or 24.04 (native recommended; WSL2 works for early stages),
≥ 8 CPU cores, ≥ 16 GB RAM, Docker.

Full step-by-step guide: [docs/stage1_setup.md](docs/stage1_setup.md).

```bash
./scripts/start_core.sh      # terminal 1: Open5GS core in Docker
./scripts/run_gnb.sh         # terminal 2: OCUDU gNB (ZMQ)
./scripts/run_ue.sh          # terminal 3: srsUE (ZMQ) in network namespace ue1
./scripts/test_e2e.sh        # terminal 4: routes + ping + iperf3 through the 5G link
```

## Repository layout

```
configs/    gNB, UE and subscriber configuration
scripts/    start/stop/test helpers
docs/       setup guides, design notes, lab notebook
```

## Network plan

| Element | Address |
|---|---|
| Docker network for the core | 10.53.1.0/24 |
| Host side of that network (gNB N2/N3 bind) | 10.53.1.1 |
| Open5GS AMF/UPF container | 10.53.1.2 |
| UE IP pool | 10.45.0.0/16 (UE gets 10.45.1.2, gateway 10.45.1.1) |
| ZMQ gNB → UE (DL) | tcp://127.0.0.1:2000 |
| ZMQ UE → gNB (UL) | tcp://127.0.0.1:2001 |

PLMN 001/01, TAC 7, band n3, 10 MHz (52 PRB, 11.52 Msps), 15 kHz SCS. Test credentials only (see `configs/`).

## License

TBD (MIT or Apache-2.0 recommended for a portfolio project).
