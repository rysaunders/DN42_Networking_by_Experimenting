#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="local-link-observation"
NS_A="pocket-link-a"
NS_B="pocket-link-b"
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
run ip link add a0 type veth peer name b0
run ip link set a0 netns "${NS_A}"
run ip link set b0 netns "${NS_B}"

section "Add addresses and bring the link up"
run ip -n "${NS_A}" addr add 10.77.0.1/30 dev a0
run ip -n "${NS_B}" addr add 10.77.0.2/30 dev b0
run ip -n "${NS_A}" link set lo up
run ip -n "${NS_A}" link set a0 up
run ip -n "${NS_B}" link set lo up
run ip -n "${NS_B}" link set b0 up

section "Inspect connected routes"
run ip -n "${NS_A}" route
run ip -n "${NS_B}" route
run ip -n "${NS_A}" route get 10.77.0.2

section "Inspect neighbor tables before traffic"
run ip -n "${NS_A}" neigh show
run ip -n "${NS_B}" neigh show

section "Capture first packet exchange"
run mkdir -p "${WORK_DIR}"
run ip netns exec "${NS_B}" timeout 8 tcpdump -n -e -i b0 -c 4 "arp or icmp" -l -U -w "${WORK_DIR}/first-ping.pcap" &
TCPDUMP_PID=$!
sleep 1
run ip netns exec "${NS_A}" ping -c 1 -W 2 10.77.0.2
wait "${TCPDUMP_PID}"
run ip netns exec "${NS_B}" tcpdump -n -e -r "${WORK_DIR}/first-ping.pcap"

section "Inspect neighbor tables after traffic"
run ip -n "${NS_A}" neigh show
run ip -n "${NS_B}" neigh show

section "Capture warm-neighbor ICMP only"
run ip netns exec "${NS_B}" timeout 8 tcpdump -n -e -i b0 -c 2 "icmp" -l -U -w "${WORK_DIR}/second-ping.pcap" &
TCPDUMP_PID=$!
sleep 1
run ip netns exec "${NS_A}" ping -c 1 -W 2 10.77.0.2
wait "${TCPDUMP_PID}"
run ip netns exec "${NS_B}" tcpdump -n -e -r "${WORK_DIR}/second-ping.pcap"

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_A}|${NS_B})( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces and capture files removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
