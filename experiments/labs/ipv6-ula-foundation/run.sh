#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="ipv6-ula-foundation"
NS_A="pocket-v6-a"
NS_B="pocket-v6-b"
WORK_DIR="/tmp/${LAB_NAME}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TRANSCRIPT_DIR="${REPO_ROOT}/experiments/transcripts/local"
# Local runs write to the ignored local transcript directory. Set
# LAB_TRANSCRIPT_PATH to a checked-in path when intentionally regenerating
# a validation transcript referenced by a chapter.

if [[ "${LAB_TRANSCRIPT_STARTED:-}" != "1" ]]; then
  mkdir -p "${TRANSCRIPT_DIR}"
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  export LAB_TRANSCRIPT_STARTED="1"
  export LAB_TRANSCRIPT_PATH="${LAB_TRANSCRIPT_PATH:-${TRANSCRIPT_DIR}/${LAB_NAME}-${timestamp}.txt}"
  exec > >(tee "${LAB_TRANSCRIPT_PATH}") 2>&1
fi

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

run() {
  printf '\n$'
  printf ' %q' "$@"
  printf '\n'
  "$@"
}

section() {
  printf '\n## %s\n' "$1"
}

cleanup() {
  set +e
  ip netns delete "${NS_A}" >/dev/null 2>&1
  ip netns delete "${NS_B}" >/dev/null 2>&1
  rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
run tcpdump --version
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_A}|${NS_B})( |$)' || true"

section "Create namespaces and link"
run ip netns add "${NS_A}"
run ip netns add "${NS_B}"
run ip link add v6a0 type veth peer name v6b0
run ip link set v6a0 netns "${NS_A}"
run ip link set v6b0 netns "${NS_B}"

section "Reduce address setup noise"
run ip netns exec "${NS_A}" sysctl -w net.ipv6.conf.all.accept_dad=0
run ip netns exec "${NS_A}" sysctl -w net.ipv6.conf.default.accept_dad=0
run ip netns exec "${NS_A}" sysctl -w net.ipv6.conf.v6a0.accept_dad=0
run ip netns exec "${NS_B}" sysctl -w net.ipv6.conf.all.accept_dad=0
run ip netns exec "${NS_B}" sysctl -w net.ipv6.conf.default.accept_dad=0
run ip netns exec "${NS_B}" sysctl -w net.ipv6.conf.v6b0.accept_dad=0

section "Add IPv6 addresses"
run ip -n "${NS_A}" addr add fd42:4242:100::1/64 dev v6a0
run ip -n "${NS_B}" addr add fd42:4242:100::2/64 dev v6b0
run ip -n "${NS_B}" link add service0 type dummy
run ip netns exec "${NS_B}" sysctl -w net.ipv6.conf.service0.accept_dad=0
run ip -n "${NS_B}" addr add fd42:4242:200::1/128 dev service0

section "Bring interfaces up"
run ip -n "${NS_A}" link set lo up
run ip -n "${NS_A}" link set v6a0 up
run ip -n "${NS_B}" link set lo up
run ip -n "${NS_B}" link set v6b0 up
run ip -n "${NS_B}" link set service0 up

section "Inspect IPv6 addresses and connected routes"
run ip -n "${NS_A}" -6 addr show dev v6a0
run ip -n "${NS_B}" -6 addr show dev v6b0
run ip -n "${NS_B}" -6 addr show dev service0
run ip -n "${NS_A}" -6 route
run ip -n "${NS_B}" -6 route

section "Inspect route lookup on the local link"
run ip -n "${NS_A}" -6 route get fd42:4242:100::2
run ip -n "${NS_A}" -6 neigh show

section "Capture first IPv6 neighbor discovery"
run mkdir -p "${WORK_DIR}"
run ip netns exec "${NS_B}" timeout 8 tcpdump -n -e -i v6b0 -c 4 "icmp6" -l -U -w "${WORK_DIR}/first-v6-ping.pcap" &
TCPDUMP_PID=$!
sleep 1
run ip netns exec "${NS_A}" ping -6 -c 1 -W 2 fd42:4242:100::2
wait "${TCPDUMP_PID}"
run ip netns exec "${NS_B}" tcpdump -n -e -r "${WORK_DIR}/first-v6-ping.pcap"
run ip -n "${NS_A}" -6 neigh show
run ip -n "${NS_B}" -6 neigh show

section "Add and inspect a ULA service-loopback route"
run ip -n "${NS_A}" -6 route add fd42:4242:200::1/128 via fd42:4242:100::2 dev v6a0
run ip -n "${NS_A}" -6 route get fd42:4242:200::1
run ip netns exec "${NS_A}" ping -6 -c 1 -W 2 fd42:4242:200::1

section "Show that the route is IPv6-specific"
run ip -n "${NS_A}" route || true
run ip -n "${NS_A}" -6 route

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_A}|${NS_B})( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces and capture files removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
