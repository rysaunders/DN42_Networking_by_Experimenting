#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="wireguard-point-to-point"

AS2="pocket-as2"
AS3="pocket-as3"

LAB_DIR="/tmp/${LAB_NAME}"

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
  ip netns delete "${AS2}" >/dev/null 2>&1
  ip netns delete "${AS3}" >/dev/null 2>&1
  rm -rf "${LAB_DIR}"
}

logged_cleanup() {
  run ip netns delete "${AS2}" || true
  run ip netns delete "${AS3}" || true
  run rm -rf "${LAB_DIR}"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
require_command wg
run wg --version
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^(${AS2}|${AS3})( |$)' || true"

section "Create two namespaces"
run install -d -m 700 "${LAB_DIR}"
run stat -c "%a %n" "${LAB_DIR}"
run ip netns add "${AS2}"
run ip netns add "${AS3}"
run ip netns list

section "Build the underlay"
run ip link add as2-underlay type veth peer name as3-underlay
run ip link set as2-underlay netns "${AS2}"
run ip link set as3-underlay netns "${AS3}"
run ip -n "${AS2}" addr add 192.0.2.1/30 dev as2-underlay
run ip -n "${AS3}" addr add 192.0.2.2/30 dev as3-underlay
run ip -n "${AS2}" link set lo up
run ip -n "${AS3}" link set lo up
run ip -n "${AS2}" link set as2-underlay up
run ip -n "${AS3}" link set as3-underlay up

section "Verify the underlay"
run ip -n "${AS2}" route get 192.0.2.2
run ip netns exec "${AS2}" ping -c 1 -W 1 192.0.2.2

section "Generate WireGuard keys"
run bash -c "umask 077; wg genkey > '${LAB_DIR}/as2.key'"
run bash -c "wg pubkey < '${LAB_DIR}/as2.key' > '${LAB_DIR}/as2.pub'"
run bash -c "umask 077; wg genkey > '${LAB_DIR}/as3.key'"
run bash -c "wg pubkey < '${LAB_DIR}/as3.key' > '${LAB_DIR}/as3.pub'"
run stat -c "%a %n" "${LAB_DIR}/as2.key" "${LAB_DIR}/as3.key"
run cat "${LAB_DIR}/as2.pub"
run cat "${LAB_DIR}/as3.pub"

AS2_PUB="$(cat "${LAB_DIR}/as2.pub")"
AS3_PUB="$(cat "${LAB_DIR}/as3.pub")"

section "Create WireGuard overlay interfaces"
run ip -n "${AS2}" link add wg23 type wireguard
run ip -n "${AS3}" link add wg23 type wireguard
run ip -n "${AS2}" addr add 10.42.23.1/30 dev wg23
run ip -n "${AS3}" addr add 10.42.23.2/30 dev wg23

section "Configure WireGuard peers"
run ip netns exec "${AS2}" wg set wg23 \
  private-key "${LAB_DIR}/as2.key" \
  listen-port 51823 \
  peer "${AS3_PUB}" \
  allowed-ips 10.42.23.2/32 \
  endpoint 192.0.2.2:51824

run ip netns exec "${AS3}" wg set wg23 \
  private-key "${LAB_DIR}/as3.key" \
  listen-port 51824 \
  peer "${AS2_PUB}" \
  allowed-ips 10.42.23.1/32 \
  endpoint 192.0.2.1:51823

run ip -n "${AS2}" link set wg23 up
run ip -n "${AS3}" link set wg23 up

section "Compare underlay and overlay route lookups"
run ip -n "${AS2}" route get 192.0.2.2
run ip -n "${AS2}" route get 10.42.23.2
run ip -n "${AS3}" route get 192.0.2.1
run ip -n "${AS3}" route get 10.42.23.1

section "Verify the overlay"
run ip netns exec "${AS2}" ping -c 2 -W 1 10.42.23.2
run ip netns exec "${AS2}" wg show wg23
run ip netns exec "${AS3}" wg show wg23

section "Show final route state"
run ip -n "${AS2}" route
run ip -n "${AS3}" route

section "Rollback"
logged_cleanup
run bash -c "ip netns list | grep -E '^(${AS2}|${AS3})( |$)' || true"
run ip route get 1.1.1.1

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces, WireGuard interfaces, and keys removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
