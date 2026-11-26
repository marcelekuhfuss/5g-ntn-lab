# Stage 1 — Your own 5G SA network on one PC

**Goal:** a phone-less, radio-less 5G network: Open5GS core (Docker) + OCUDU gNB + srsUE,
connected over ZMQ, with `ping` and `iperf3` running through the 5G data path.

Based on the official OCUDU tutorial: https://docs.ocudu.org/tutorials/srsue/
(OCUDU is the Linux Foundation open-source CU/DU stack that evolved from srsRAN Project.)

**Time:** 2–3 sessions of 2–3 hours. Most of it is compiling and debugging, which is expected.

---

## 0. Machine

- Ubuntu 22.04 or 24.04, ideally **native** (dual-boot or a dedicated personal PC).
  WSL2 can work for this stage, but ZMQ timing is less stable there.
- Use a **personal** computer, not a university laptop, so the project is clearly yours.
- ≥ 8 cores, ≥ 16 GB RAM, ~20 GB free disk.

## 1. Install dependencies

```bash
sudo apt update
sudo apt install -y git cmake make gcc g++ clang pkg-config \
  libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev \
  libzmq3-dev libboost-program-options-dev libconfig++-dev \
  iperf3 net-tools
```

**Compiler:** OCUDU needs **GCC ≥ 15.2 or Clang ≥ 14**. Ubuntu 22.04/24.04 ship an older GCC
(11/13), so we build OCUDU with Clang (step 2). srsUE builds fine with the default GCC.

Docker (official instructions: https://docs.docker.com/engine/install/ubuntu/), then:

```bash
sudo usermod -aG docker $USER   # log out and back in afterwards
docker run hello-world          # check it works
```

## 2. Build OCUDU (the gNB)

```bash
mkdir -p ~/src && cd ~/src
git clone https://gitlab.com/ocudu/ocudu.git
cd ocudu
git branch -r | grep release            # list release branches, e.g. origin/release_26_10
git checkout release_26_10              # pin the latest release, and note it in docs/lab_notebook.md
mkdir build && cd build
CC=clang CXX=clang++ cmake .. -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j$(nproc)
```

Check: `./apps/gnb/gnb --version`. In the CMake output, look for `Found libZEROMQ`.
If ZeroMQ was not found, install `libzmq3-dev`, **delete `build/`** and run CMake again
(ZMQ installed after a first build is not picked up).

> Release 26.10 is the first with 3GPP Rel-17 NTN support — we will need it in stage 5.

## 3. Build srsRAN 4G (for srsUE)

OCUDU is the network side only; the simulated phone, srsUE, lives in the srsRAN 4G repository
(23.11 or later). Its 5G support is in maintenance mode (no new features), which is fine
for a ZMQ lab.

```bash
cd ~/src
git clone https://github.com/srsran/srsRAN_4G.git
cd srsRAN_4G
mkdir build && cd build
cmake ..
make -j$(nproc)
```

Check: `./srsue/src/srsue --version`. In the CMake output, confirm that ZEROMQ was found.

## 4. Get this repository onto the Linux machine

```bash
cd ~/src
git clone <your GitHub URL>/5g-ntn-lab.git    # or copy the folder over
cd 5g-ntn-lab
chmod +x scripts/*.sh
```

The scripts expect OCUDU at `~/src/ocudu` and srsRAN 4G at `~/src/srsRAN_4G`.
Elsewhere? Set `OCUDU_DIR`, or `GNB_BIN` / `UE_BIN` to the binaries.

## 5. Run it (four terminals)

**Terminal 1: core**
```bash
./scripts/start_core.sh
```
Wait until the logs settle (AMF, SMF and UPF started).

**Terminal 2: gNB**
```bash
./scripts/run_gnb.sh
```
Success looks like: `--== OCUDU gNB ... ==--`, `Connecting to AMF on 10.53.1.2:38412`, then a
`Cell pci=1, bw=10 MHz, dl_arfcn=368500 (n3) ...` line. The core log (terminal 1) shows
`gNB-N2 accepted[10.53.1.1]` and `Number of gNBs is now 1`.

**Terminal 3: UE**
```bash
./scripts/run_ue.sh
```
Success looks like: `RRC Connected`, then `PDU Session Establishment successful. IP: 10.45.1.2`.

**Terminal 4: test**
```bash
./scripts/test_e2e.sh
```

Stop everything with `./scripts/stop_all.sh`.

## 6. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| CMake/compile errors about C++ features | Old GCC: build with Clang (`CC=clang CXX=clang++`, fresh `build/` folder) |
| gNB cannot reach AMF | Core not up yet, or Docker bridge is not `10.53.1.1`: check `ip -o addr show \| grep 10.53.1.1` |
| UE stuck before `RRC Connected` | Start order: core → gNB → UE. Ports 2000/2001 must be mirrored, and sample rate / PRBs must match (11.52 Msps, 52 PRB) |
| `Authentication failure` / reject, or `Cannot find IMSI in DB` | IMSI/K/OPc differ between `configs/ue_zmq.conf` and `configs/subscriber_db.csv`; restart the core after editing the CSV |
| Ping fails but UE attached | Rerun `test_e2e.sh` (routes); check `sudo ip netns exec ue1 ip a` shows `tun_srsue` |
| Lots of `Late` / underflow messages | CPU too slow or busy (common on WSL2/VMs): close other apps, use native Linux |

For a closer look, set `all_level: info` in `configs/gnb_zmq.yaml` and `all_level = info` in
`configs/ue_zmq.conf`, then read `/tmp/gnb.log` and `/tmp/ue.log`. The Open5GS web UI is at
http://localhost:9999 (admin / 1423).

## 7. Done when

- [ ] UE attaches and gets 10.45.1.2
- [ ] Uplink and downlink ping succeed
- [ ] iperf3 result recorded in `docs/lab_notebook.md` (with OCUDU release and CPU model)
- [ ] Screenshot or short screen recording saved (for the README and a LinkedIn post)
- [ ] Committed and pushed to GitHub

**Next (stage 2):** move the ZMQ ports so that gNB and UE talk to a GNU Radio broker
instead of each other. That broker is where channels and jammers get added.
