#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="dns-and-naming-foundation"
NS_CLIENT="pocket-dns-client"
NS_SERVER="pocket-dns-server"
WORK_DIR="/tmp/${LAB_NAME}"
DNS_PID=""
HTTP_PID=""

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
  if [[ -n "${HTTP_PID}" ]]; then
    kill "${HTTP_PID}" >/dev/null 2>&1
    wait "${HTTP_PID}" >/dev/null 2>&1
  fi
  if [[ -n "${DNS_PID}" ]]; then
    kill "${DNS_PID}" >/dev/null 2>&1
    wait "${DNS_PID}" >/dev/null 2>&1
  fi
  ip netns delete "${NS_CLIENT}" >/dev/null 2>&1
  ip netns delete "${NS_SERVER}" >/dev/null 2>&1
  rm -rf "${WORK_DIR}"
  rm -rf "/etc/netns/${NS_CLIENT}"
  rm -rf "/etc/netns/${NS_SERVER}"
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
run dnsmasq --version
run python3 --version
run curl --version
run command -v pkill
run bash -c "getent --help >/dev/null && echo 'getent is available'"
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
run ip -n "${NS_CLIENT}" addr add 10.89.0.1/30 dev client0
run ip -n "${NS_SERVER}" addr add 10.89.0.2/30 dev server0
run ip -n "${NS_CLIENT}" link set lo up
run ip -n "${NS_CLIENT}" link set client0 up
run ip -n "${NS_SERVER}" link set lo up
run ip -n "${NS_SERVER}" link set server0 up
run ip -n "${NS_CLIENT}" route
run ip -n "${NS_SERVER}" route

section "Prove routing before naming"
run ip -n "${NS_CLIENT}" route get 10.89.0.2
run ip netns exec "${NS_CLIENT}" ping -c 1 -W 2 10.89.0.2
run ip netns exec "${NS_CLIENT}" getent hosts www.pocket.test || true

section "Start a local DNS server"
run mkdir -p "${WORK_DIR}"
run bash -c "exec ip netns exec '${NS_SERVER}' dnsmasq --no-daemon --no-resolv --bind-interfaces --interface=server0 --listen-address=10.89.0.2 --address=/www.pocket.test/10.89.0.2 --log-queries --log-facility=- >'${WORK_DIR}/dnsmasq.log' 2>&1" &
DNS_PID=$!
sleep 1
run ip netns exec "${NS_SERVER}" ss -lunp

section "Point only the client namespace at the lab nameserver"
run mkdir -p "/etc/netns/${NS_CLIENT}"
run bash -c "printf 'nameserver 10.89.0.2\noptions timeout:1 attempts:1\n' > '/etc/netns/${NS_CLIENT}/resolv.conf'"
run cat "/etc/netns/${NS_CLIENT}/resolv.conf"

section "Resolve the lab name"
run ip netns exec "${NS_CLIENT}" getent hosts www.pocket.test
run tail -n 20 "${WORK_DIR}/dnsmasq.log"

section "Start a named HTTP service"
run mkdir -p "${WORK_DIR}/web"
run bash -c "printf 'hello from named pocket service\n' > '${WORK_DIR}/web/index.html'"
run bash -c "exec ip netns exec '${NS_SERVER}' python3 -m http.server 8080 --bind 10.89.0.2 --directory '${WORK_DIR}/web' >'${WORK_DIR}/http.log' 2>&1" &
HTTP_PID=$!
sleep 1
run ip netns exec "${NS_SERVER}" ss -ltnp
run ip netns exec "${NS_CLIENT}" curl -sS --max-time 3 http://www.pocket.test:8080/

section "Failure mode: route works and name fails"
run ip netns exec "${NS_CLIENT}" getent hosts missing.pocket.test || true
run ip -n "${NS_CLIENT}" route get 10.89.0.2
run ip netns exec "${NS_CLIENT}" curl -sS --max-time 3 http://10.89.0.2:8080/

section "Failure mode: name works and service fails"
run ip netns exec "${NS_CLIENT}" getent hosts www.pocket.test
run ip netns exec "${NS_SERVER}" pkill -f "python3 -m http.server 8080" || true
wait "${HTTP_PID}" >/dev/null 2>&1 || true
HTTP_PID=""
run ip netns exec "${NS_CLIENT}" getent hosts www.pocket.test
run ip netns exec "${NS_CLIENT}" curl -sS --connect-timeout 2 --max-time 3 http://www.pocket.test:8080/ || true

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^(${NS_CLIENT}|${NS_SERVER})( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces, resolver config, services, and files removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
