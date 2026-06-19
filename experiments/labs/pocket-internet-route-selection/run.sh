#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="pocket-internet-route-selection"
EDGE="pocket-rs-edge"

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
  ip netns delete "${EDGE}" >/dev/null 2>&1
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^${EDGE}( |$)' || true"

section "Create the Pocket Internet edge router"
run ip netns add "${EDGE}"
run ip netns list

section "Create local exits"
run ip -n "${EDGE}" link add edge-transit0 type dummy
run ip -n "${EDGE}" link add edge-service0 type dummy
run ip -n "${EDGE}" link add edge-host0 type dummy

section "Assign interface addresses"
run ip -n "${EDGE}" addr add 10.52.0.1/30 dev edge-transit0
run ip -n "${EDGE}" addr add 10.52.1.1/30 dev edge-service0
run ip -n "${EDGE}" addr add 10.52.2.1/30 dev edge-host0

section "Bring interfaces up"
run ip -n "${EDGE}" link set lo up
run ip -n "${EDGE}" link set edge-transit0 up
run ip -n "${EDGE}" link set edge-service0 up
run ip -n "${EDGE}" link set edge-host0 up

section "Show connected routes"
run ip -n "${EDGE}" route

section "Probe an off-link next hop"
run ip -n "${EDGE}" route add 172.20.99.0/24 via 10.52.9.2 dev edge-transit0 || true

section "Install overlapping routes"
run ip -n "${EDGE}" route add 172.20.0.0/16 via 10.52.0.2 dev edge-transit0
run ip -n "${EDGE}" route add 172.20.3.0/24 via 10.52.1.2 dev edge-service0
run ip -n "${EDGE}" route add 172.20.3.42/32 via 10.52.2.2 dev edge-host0
run ip -n "${EDGE}" route

section "Inspect longest-prefix match"
run ip -n "${EDGE}" route get 172.20.3.42
run ip -n "${EDGE}" route get 172.20.3.99
run ip -n "${EDGE}" route get 172.20.9.9

section "Remove the exact host route"
run ip -n "${EDGE}" route delete 172.20.3.42/32
run ip -n "${EDGE}" route get 172.20.3.42

section "Remove the /24 route"
run ip -n "${EDGE}" route delete 172.20.3.0/24
run ip -n "${EDGE}" route get 172.20.3.42

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^${EDGE}( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespace removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
