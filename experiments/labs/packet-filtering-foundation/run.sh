#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="packet-filtering-foundation"
NS_CLIENT="pocket-filter-client"
NS_SERVER="pocket-filter-server"
WORK_DIR="/tmp/${LAB_NAME}"
SERVER_PID=""

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
  if [[ -n "${SERVER_PID}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1
    wait "${SERVER_PID}" >/dev/null 2>&1
  fi
  ip netns delete "${NS_CLIENT}" >/dev/null 2>&1
  ip netns delete "${NS_SERVER}" >/dev/null 2>&1
  rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
run nft --version
run python3 --version
run curl --version
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_CLIENT}|${NS_SERVER})( |$)' || true"

section "Create namespaces and link"
run ip netns add "${NS_CLIENT}"
run ip netns add "${NS_SERVER}"
run ip link add client0 type veth peer name server0
run ip link set client0 netns "${NS_CLIENT}"
run ip link set server0 netns "${NS_SERVER}"

section "Add addresses and bring the link up"
run ip -n "${NS_CLIENT}" addr add 10.88.0.1/30 dev client0
run ip -n "${NS_SERVER}" addr add 10.88.0.2/30 dev server0
run ip -n "${NS_CLIENT}" link set lo up
run ip -n "${NS_CLIENT}" link set client0 up
run ip -n "${NS_SERVER}" link set lo up
run ip -n "${NS_SERVER}" link set server0 up

section "Create and start a local HTTP service"
run mkdir -p "${WORK_DIR}/web"
run bash -c "printf 'packet filtering lab ok\n' > '${WORK_DIR}/web/index.html'"
run bash -c "exec ip netns exec '${NS_SERVER}' python3 -m http.server 8080 --bind 10.88.0.2 --directory '${WORK_DIR}/web' >'${WORK_DIR}/http.log' 2>&1" &
SERVER_PID=$!
sleep 1
run ip netns exec "${NS_SERVER}" ss -ltnp

section "Prove routing and service reachability before filtering"
run ip -n "${NS_CLIENT}" route get 10.88.0.2
run ip netns exec "${NS_CLIENT}" ping -c 1 -W 2 10.88.0.2
run ip netns exec "${NS_CLIENT}" curl -sS --max-time 3 http://10.88.0.2:8080/

section "Install a namespace-local nftables filter"
run ip netns exec "${NS_SERVER}" nft add table inet pocket_filter
run ip netns exec "${NS_SERVER}" nft add chain inet pocket_filter input "{ type filter hook input priority 0; policy drop; }"
run ip netns exec "${NS_SERVER}" nft add rule inet pocket_filter input iifname lo accept
run ip netns exec "${NS_SERVER}" nft add rule inet pocket_filter input ip saddr 10.88.0.1 tcp dport 8080 counter accept
run ip netns exec "${NS_SERVER}" nft add rule inet pocket_filter input ip protocol icmp counter drop
run ip netns exec "${NS_SERVER}" nft list ruleset

section "Prove route lookup is unchanged"
run ip -n "${NS_CLIENT}" route get 10.88.0.2

section "Prove intended service traffic is allowed"
run ip netns exec "${NS_CLIENT}" curl -sS --max-time 3 http://10.88.0.2:8080/

section "Prove unrelated ICMP traffic is denied"
run ip netns exec "${NS_CLIENT}" ping -c 1 -W 2 10.88.0.2 || true
run ip netns exec "${NS_SERVER}" nft list ruleset

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_CLIENT}|${NS_SERVER})( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces, filters, service, and files removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
