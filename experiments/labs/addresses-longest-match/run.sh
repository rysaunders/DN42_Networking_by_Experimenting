#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="addresses-longest-match"
NS="addrmatch"

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
  ip netns delete "${NS}" >/dev/null 2>&1
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^${NS}( |$)' || true"

section "Create namespace"
run ip netns add "${NS}"
run ip netns list

section "Create local-only interfaces"
run ip -n "${NS}" link add broad0 type dummy
run ip -n "${NS}" link add specific0 type dummy
run ip -n "${NS}" link add host0 type dummy

section "Add interface addresses"
run ip -n "${NS}" addr add 10.0.0.1/30 dev broad0
run ip -n "${NS}" addr add 10.0.1.1/30 dev specific0
run ip -n "${NS}" addr add 10.0.2.1/30 dev host0

section "Bring interfaces up"
run ip -n "${NS}" link set lo up
run ip -n "${NS}" link set broad0 up
run ip -n "${NS}" link set specific0 up
run ip -n "${NS}" link set host0 up

section "Show connected routes"
run ip -n "${NS}" route

section "Install overlapping routes"
run ip -n "${NS}" route add default via 10.0.0.2 dev broad0
run ip -n "${NS}" route add 172.20.0.0/16 via 10.0.0.2 dev broad0
run ip -n "${NS}" route add 172.20.30.0/24 via 10.0.1.2 dev specific0
run ip -n "${NS}" route add 172.20.30.42/32 via 10.0.2.2 dev host0
run ip -n "${NS}" route

section "Predict and inspect longest-prefix match"
run ip -n "${NS}" route get 172.20.30.42
run ip -n "${NS}" route get 172.20.30.99
run ip -n "${NS}" route get 172.20.99.5
run ip -n "${NS}" route get 203.0.113.10

section "Remove the host route"
run ip -n "${NS}" route delete 172.20.30.42/32
run ip -n "${NS}" route get 172.20.30.42

section "Remove the more-specific prefix"
run ip -n "${NS}" route delete 172.20.30.0/24
run ip -n "${NS}" route get 172.20.30.42

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^${NS}( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespace removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
