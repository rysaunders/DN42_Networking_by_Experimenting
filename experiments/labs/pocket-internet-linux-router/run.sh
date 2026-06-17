#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="pocket-internet-linux-router"
NS_LEFT="pocket-left"
NS_ROUTER="pocket-router"
NS_RIGHT="pocket-right"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TRANSCRIPT_DIR="${REPO_ROOT}/experiments/transcripts"

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
  ip netns delete "${NS_LEFT}" >/dev/null 2>&1
  ip netns delete "${NS_ROUTER}" >/dev/null 2>&1
  ip netns delete "${NS_RIGHT}" >/dev/null 2>&1
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_LEFT}|${NS_ROUTER}|${NS_RIGHT})( |$)' || true"

section "Create isolated namespaces"
run ip netns add "${NS_LEFT}"
run ip netns add "${NS_ROUTER}"
run ip netns add "${NS_RIGHT}"
run ip netns list

section "Create veth links"
run ip link add left0 type veth peer name rtr-left0
run ip link set left0 netns "${NS_LEFT}"
run ip link set rtr-left0 netns "${NS_ROUTER}"
run ip link add right0 type veth peer name rtr-right0
run ip link set right0 netns "${NS_RIGHT}"
run ip link set rtr-right0 netns "${NS_ROUTER}"

section "Inspect links before addresses"
run ip -all netns exec ip link show

section "Configure addresses"
run ip -n "${NS_LEFT}" addr add 10.10.1.2/30 dev left0
run ip -n "${NS_ROUTER}" addr add 10.10.1.1/30 dev rtr-left0
run ip -n "${NS_ROUTER}" addr add 10.10.2.1/30 dev rtr-right0
run ip -n "${NS_RIGHT}" addr add 10.10.2.2/30 dev right0

section "Bring links up"
run ip -n "${NS_LEFT}" link set lo up
run ip -n "${NS_LEFT}" link set left0 up
run ip -n "${NS_ROUTER}" link set lo up
run ip -n "${NS_ROUTER}" link set rtr-left0 up
run ip -n "${NS_ROUTER}" link set rtr-right0 up
run ip -n "${NS_RIGHT}" link set lo up
run ip -n "${NS_RIGHT}" link set right0 up

section "Start with forwarding disabled"
run ip netns exec "${NS_ROUTER}" sysctl -w net.ipv4.ip_forward=0

section "Show directly connected routes"
run ip -all netns exec ip route

section "Route lookup before static routes"
run ip -n "${NS_LEFT}" route get 10.10.2.2 || true
run ip netns exec "${NS_LEFT}" ping -c 1 -W 1 10.10.2.2 || true

section "Add routes through the router namespace"
run ip -n "${NS_LEFT}" route add 10.10.2.0/30 via 10.10.1.1 dev left0
run ip -n "${NS_RIGHT}" route add 10.10.1.0/30 via 10.10.2.1 dev right0

section "Route lookup after static routes"
run ip -n "${NS_LEFT}" route get 10.10.2.2
run ip -n "${NS_RIGHT}" route get 10.10.1.2

section "Ping still fails before forwarding is enabled"
run ip netns exec "${NS_ROUTER}" sysctl net.ipv4.ip_forward
run ip netns exec "${NS_LEFT}" ping -c 1 -W 1 10.10.2.2 || true

section "Enable forwarding inside the router namespace"
run ip netns exec "${NS_ROUTER}" sysctl -w net.ipv4.ip_forward=1

section "Forward traffic through the router namespace"
run ip netns exec "${NS_LEFT}" ping -c 2 -W 1 10.10.2.2
run ip netns exec "${NS_RIGHT}" ping -c 2 -W 1 10.10.1.2

section "Inspect router counters and routes"
run ip -n "${NS_ROUTER}" -s link show rtr-left0
run ip -n "${NS_ROUTER}" -s link show rtr-right0
run ip -n "${NS_ROUTER}" route get 10.10.2.2
run ip -n "${NS_ROUTER}" route get 10.10.1.2

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_LEFT}|${NS_ROUTER}|${NS_RIGHT})( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
