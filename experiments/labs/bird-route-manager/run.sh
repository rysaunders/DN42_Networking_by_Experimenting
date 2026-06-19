#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="bird-route-manager"
NS="birdlab"
LAB_DIR="/tmp/${LAB_NAME}"
SOCKET="${LAB_DIR}/bird.ctl"
PID_FILE="${LAB_DIR}/bird.pid"
CONFIG_NO_EXPORT="${LAB_DIR}/bird-no-export.conf"
CONFIG_EXPORT="${LAB_DIR}/bird-export.conf"
STATIC_PREFIX="172.20.99.0/24"
STATIC_TARGET="172.20.99.1"

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
  if [[ -f "${PID_FILE}" ]]; then
    ip netns exec "${NS}" kill "$(cat "${PID_FILE}")" >/dev/null 2>&1 || true
  fi
  ip netns delete "${NS}" >/dev/null 2>&1
  rm -rf "${LAB_DIR}"
}

logged_cleanup() {
  if [[ -f "${PID_FILE}" ]]; then
    run ip netns exec "${NS}" kill "$(cat "${PID_FILE}")" || true
  fi
  run ip netns delete "${NS}" || true
  run rm -rf "${LAB_DIR}"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

birdc_lab() {
  ip netns exec "${NS}" birdc -s "${SOCKET}" "$@"
}

wait_for_bird_route() {
  local prefix="$1"
  local attempt

  for attempt in $(seq 1 30); do
    if birdc_lab show route "${prefix}" | grep -q "${prefix}"; then
      return 0
    fi
    sleep 1
  done

  birdc_lab show route all
  printf 'BIRD route %s did not appear\n' "${prefix}" >&2
  exit 1
}

wait_for_kernel_route() {
  local prefix="$1"
  local attempt

  for attempt in $(seq 1 30); do
    if ip -n "${NS}" route show "${prefix}" | grep -q "${prefix}"; then
      return 0
    fi
    sleep 1
  done

  ip -n "${NS}" route
  printf 'Kernel route %s did not appear\n' "${prefix}" >&2
  exit 1
}

write_config_no_export() {
  cat >"${CONFIG_NO_EXPORT}" <<'EOF'
log stderr all;
router id 172.20.50.1;

protocol device {
  scan time 1;
}

protocol direct direct_service {
  ipv4;
  interface "svc0";
}

protocol static static_lab {
  ipv4;
  route 172.20.99.0/24 blackhole;
}

protocol kernel kernel_ipv4 {
  ipv4 {
    import none;
    export none;
  };
  scan time 1;
}
EOF
}

write_config_export() {
  cat >"${CONFIG_EXPORT}" <<'EOF'
log stderr all;
router id 172.20.50.1;

protocol device {
  scan time 1;
}

protocol direct direct_service {
  ipv4;
  interface "svc0";
}

protocol static static_lab {
  ipv4;
  route 172.20.99.0/24 blackhole;
}

filter kernel_export_lab {
  if net = 172.20.99.0/24 then accept;
  reject;
}

protocol kernel kernel_ipv4 {
  ipv4 {
    import none;
    export filter kernel_export_lab;
  };
  scan time 1;
}
EOF
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
require_command bird
require_command birdc
run bird --version
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^${NS}( |$)' || true"

section "Create one namespace"
run mkdir -p "${LAB_DIR}"
run ip netns add "${NS}"
run ip -n "${NS}" link set lo up
run ip -n "${NS}" link add svc0 type dummy
run ip -n "${NS}" addr add 172.20.50.1/32 dev svc0
run ip -n "${NS}" link set svc0 up

section "Inspect Linux before BIRD"
run ip -n "${NS}" addr show svc0
run ip -n "${NS}" route show
run ip -n "${NS}" route show "${STATIC_PREFIX}" || true
run ip -n "${NS}" route get "${STATIC_TARGET}" || true

section "Write BIRD config without kernel export"
write_config_no_export
run cat "${CONFIG_NO_EXPORT}"
run bird -p -c "${CONFIG_NO_EXPORT}"
run ip netns exec "${NS}" bird -c "${CONFIG_NO_EXPORT}" -s "${SOCKET}" -P "${PID_FILE}"

section "Inspect BIRD routes before kernel export"
wait_for_bird_route "172.20.50.1/32"
wait_for_bird_route "${STATIC_PREFIX}"
run ip netns exec "${NS}" birdc -s "${SOCKET}" show protocols
run ip netns exec "${NS}" birdc -s "${SOCKET}" show route all
run ip -n "${NS}" route show "${STATIC_PREFIX}" || true
run ip -n "${NS}" route get "${STATIC_TARGET}" || true

section "Reload BIRD with explicit kernel export"
write_config_export
run cat "${CONFIG_EXPORT}"
run bird -p -c "${CONFIG_EXPORT}"
run cp "${CONFIG_EXPORT}" "${CONFIG_NO_EXPORT}"
run ip netns exec "${NS}" birdc -s "${SOCKET}" configure

section "Inspect Linux after kernel export"
wait_for_kernel_route "${STATIC_PREFIX}"
run ip netns exec "${NS}" birdc -s "${SOCKET}" show protocols
run ip netns exec "${NS}" birdc -s "${SOCKET}" show route "${STATIC_PREFIX}" all
run ip -n "${NS}" route show "${STATIC_PREFIX}"
run ip -n "${NS}" route get "${STATIC_TARGET}" || true

section "Rollback"
logged_cleanup
run bash -c "ip netns list | grep -E '^${NS}( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespace and BIRD state removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
