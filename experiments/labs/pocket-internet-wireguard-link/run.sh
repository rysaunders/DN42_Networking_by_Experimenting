#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="pocket-internet-wireguard-link"

AS1="pocket-as1"
AS2="pocket-as2"
AS3="pocket-as3"
AS4="pocket-as4"

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

bird_pid_file() {
  printf '%s/%s.pid' "${LAB_DIR}" "$1"
}

bird_socket() {
  printf '%s/%s.ctl' "${LAB_DIR}" "$1"
}

stop_bird() {
  local ns="$1"
  local pid_file
  pid_file="$(bird_pid_file "${ns}")"

  if [[ -f "${pid_file}" ]]; then
    ip netns exec "${ns}" kill "$(cat "${pid_file}")" >/dev/null 2>&1 || true
  fi
}

cleanup() {
  set +e
  stop_bird "${AS1}"
  stop_bird "${AS2}"
  stop_bird "${AS3}"
  stop_bird "${AS4}"
  ip netns delete "${AS1}" >/dev/null 2>&1
  ip netns delete "${AS2}" >/dev/null 2>&1
  ip netns delete "${AS3}" >/dev/null 2>&1
  ip netns delete "${AS4}" >/dev/null 2>&1
  rm -rf "${LAB_DIR}"
}

logged_cleanup() {
  stop_bird "${AS1}"
  stop_bird "${AS2}"
  stop_bird "${AS3}"
  stop_bird "${AS4}"
  run ip netns delete "${AS1}" || true
  run ip netns delete "${AS2}" || true
  run ip netns delete "${AS3}" || true
  run ip netns delete "${AS4}" || true
  run rm -rf "${LAB_DIR}"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

write_bird_config() {
  local ns="$1"
  local router_id="$2"
  local local_as="$3"
  shift 3

  local config="${LAB_DIR}/${ns}.conf"
  local socket
  local pid_file
  socket="$(bird_socket "${ns}")"
  pid_file="$(bird_pid_file "${ns}")"

  {
    printf 'log stderr all;\n'
    printf 'router id %s;\n\n' "${router_id}"
    printf 'protocol device {\n'
    printf '  scan time 1;\n'
    printf '}\n\n'
    printf 'protocol direct direct_loopbacks {\n'
    printf '  ipv4;\n'
    printf '  interface "lo";\n'
    printf '}\n\n'
    printf 'protocol kernel kernel_ipv4 {\n'
    printf '  ipv4 {\n'
    printf '    import none;\n'
    printf '    export all;\n'
    printf '  };\n'
    printf '  scan time 1;\n'
    printf '}\n\n'
    printf 'filter pocket_import {\n'
    printf '  if net = 172.20.1.1/32 then accept;\n'
    printf '  if net = 172.20.2.1/32 then accept;\n'
    printf '  if net = 172.20.3.1/32 then accept;\n'
    printf '  if net = 172.20.4.1/32 then accept;\n'
    printf '  reject;\n'
    printf '}\n\n'
    printf 'filter pocket_export {\n'
    printf '  if net = 172.20.1.1/32 then accept;\n'
    printf '  if net = 172.20.2.1/32 then accept;\n'
    printf '  if net = 172.20.3.1/32 then accept;\n'
    printf '  if net = 172.20.4.1/32 then accept;\n'
    printf '  reject;\n'
    printf '}\n\n'

    while [[ "$#" -gt 0 ]]; do
      local protocol_name="$1"
      local neighbor_ip="$2"
      local neighbor_as="$3"
      local source_ip="$4"
      shift 4

      printf 'protocol bgp %s {\n' "${protocol_name}"
      printf '  local as %s;\n' "${local_as}"
      printf '  neighbor %s as %s;\n' "${neighbor_ip}" "${neighbor_as}"
      printf '  source address %s;\n' "${source_ip}"
      printf '  check link yes;\n'
      printf '  ipv4 {\n'
      printf '    import filter pocket_import;\n'
      printf '    export filter pocket_export;\n'
      printf '  };\n'
      printf '}\n\n'
    done
  } >"${config}"

  run bird -p -c "${config}"
  run ip netns exec "${ns}" bird -c "${config}" -s "${socket}" -P "${pid_file}"
}

birdc_ns() {
  local ns="$1"
  shift
  ip netns exec "${ns}" birdc -s "$(bird_socket "${ns}")" "$@"
}

wait_for_bgp() {
  local ns="$1"
  local expected="$2"
  local attempt

  for attempt in $(seq 1 90); do
    local established
    established="$(birdc_ns "${ns}" show protocols | awk '/BGP/ && /Established/ { count++ } END { print count + 0 }')"
    if [[ "${established}" -eq "${expected}" ]]; then
      return 0
    fi
    sleep 1
  done

  birdc_ns "${ns}" show protocols all
  printf 'BGP sessions in %s did not reach expected count %s\n' "${ns}" "${expected}" >&2
  exit 1
}

wait_for_route() {
  local ns="$1"
  local prefix="$2"
  local attempt

  for attempt in $(seq 1 90); do
    if ip -n "${ns}" route show "${prefix}" | grep -q "${prefix}"; then
      return 0
    fi
    sleep 1
  done

  birdc_ns "${ns}" show route all
  ip -n "${ns}" route
  printf 'Route %s did not appear in namespace %s\n' "${prefix}" "${ns}" >&2
  exit 1
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
require_command bird
require_command birdc
require_command wg
run bird --version
run wg --version
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^(${AS1}|${AS2}|${AS3}|${AS4})( |$)' || true"

section "Create AS-shaped namespaces"
run mkdir -p "${LAB_DIR}"
run ip netns add "${AS1}"
run ip netns add "${AS2}"
run ip netns add "${AS3}"
run ip netns add "${AS4}"
run ip netns list

section "Create veth links"
run ip link add as1-as2 type veth peer name as2-as1
run ip link set as1-as2 netns "${AS1}"
run ip link set as2-as1 netns "${AS2}"

run ip link add as3-as4 type veth peer name as4-as3
run ip link set as3-as4 netns "${AS3}"
run ip link set as4-as3 netns "${AS4}"

run ip link add as4-as1 type veth peer name as1-as4
run ip link set as4-as1 netns "${AS4}"
run ip link set as1-as4 netns "${AS1}"

section "Create AS2-AS3 underlay link"
run ip link add as2-underlay type veth peer name as3-underlay
run ip link set as2-underlay netns "${AS2}"
run ip link set as3-underlay netns "${AS3}"

section "Configure service and veth addresses"
run ip -n "${AS1}" addr add 172.20.1.1/32 dev lo
run ip -n "${AS2}" addr add 172.20.2.1/32 dev lo
run ip -n "${AS3}" addr add 172.20.3.1/32 dev lo
run ip -n "${AS4}" addr add 172.20.4.1/32 dev lo

run ip -n "${AS1}" addr add 10.42.12.1/30 dev as1-as2
run ip -n "${AS2}" addr add 10.42.12.2/30 dev as2-as1
run ip -n "${AS3}" addr add 10.42.34.1/30 dev as3-as4
run ip -n "${AS4}" addr add 10.42.34.2/30 dev as4-as3
run ip -n "${AS4}" addr add 10.42.41.1/30 dev as4-as1
run ip -n "${AS1}" addr add 10.42.41.2/30 dev as1-as4

section "Configure underlay addresses"
run ip -n "${AS2}" addr add 192.0.2.1/30 dev as2-underlay
run ip -n "${AS3}" addr add 192.0.2.2/30 dev as3-underlay

section "Bring veth and underlay links up"
for ns in "${AS1}" "${AS2}" "${AS3}" "${AS4}"; do
  run ip -n "${ns}" link set lo up
  run ip netns exec "${ns}" sysctl -w net.ipv4.ip_forward=1
done
run ip -n "${AS1}" link set as1-as2 up
run ip -n "${AS1}" link set as1-as4 up
run ip -n "${AS2}" link set as2-as1 up
run ip -n "${AS2}" link set as2-underlay up
run ip -n "${AS3}" link set as3-underlay up
run ip -n "${AS3}" link set as3-as4 up
run ip -n "${AS4}" link set as4-as3 up
run ip -n "${AS4}" link set as4-as1 up

section "Generate WireGuard keys"
run bash -c "umask 077; wg genkey > '${LAB_DIR}/as2.key'"
run bash -c "wg pubkey < '${LAB_DIR}/as2.key' > '${LAB_DIR}/as2.pub'"
run bash -c "umask 077; wg genkey > '${LAB_DIR}/as3.key'"
run bash -c "wg pubkey < '${LAB_DIR}/as3.key' > '${LAB_DIR}/as3.pub'"
run chmod 600 "${LAB_DIR}/as2.key" "${LAB_DIR}/as3.key"
run cat "${LAB_DIR}/as2.pub"
run cat "${LAB_DIR}/as3.pub"

AS2_PUB="$(cat "${LAB_DIR}/as2.pub")"
AS3_PUB="$(cat "${LAB_DIR}/as3.pub")"

section "Create WireGuard overlay interfaces"
run ip -n "${AS2}" link add wg23 type wireguard
run ip -n "${AS3}" link add wg23 type wireguard

run ip -n "${AS2}" addr add 10.42.23.1/30 dev wg23
run ip -n "${AS3}" addr add 10.42.23.2/30 dev wg23

run ip netns exec "${AS2}" wg set wg23 \
  private-key "${LAB_DIR}/as2.key" \
  listen-port 51823 \
  peer "${AS3_PUB}" \
  allowed-ips 10.42.23.2/32,172.20.3.1/32,172.20.4.1/32 \
  endpoint 192.0.2.2:51824

run ip netns exec "${AS3}" wg set wg23 \
  private-key "${LAB_DIR}/as3.key" \
  listen-port 51824 \
  peer "${AS2_PUB}" \
  allowed-ips 10.42.23.1/32,172.20.1.1/32,172.20.2.1/32 \
  endpoint 192.0.2.1:51823

run ip -n "${AS2}" link set wg23 up
run ip -n "${AS3}" link set wg23 up

section "Verify underlay and overlay links"
run ip -n "${AS2}" route get 192.0.2.2
run ip netns exec "${AS2}" ping -c 1 -W 1 192.0.2.2
run ip -n "${AS2}" route get 10.42.23.2
run ip netns exec "${AS2}" ping -c 2 -W 1 10.42.23.2
run ip netns exec "${AS2}" wg show wg23

section "Show connected routes before BGP"
run ip -n "${AS2}" route
run ip -n "${AS3}" route
run ip -n "${AS1}" route show 172.20.3.1 || true

section "Write and validate BIRD configs"
write_bird_config "${AS1}" "172.20.1.1" "4242420001" \
  "to_as2" "10.42.12.2" "4242420002" "10.42.12.1" \
  "to_as4" "10.42.41.1" "4242420004" "10.42.41.2"

write_bird_config "${AS2}" "172.20.2.1" "4242420002" \
  "to_as1" "10.42.12.1" "4242420001" "10.42.12.2" \
  "to_as3" "10.42.23.2" "4242420003" "10.42.23.1"

write_bird_config "${AS3}" "172.20.3.1" "4242420003" \
  "to_as2" "10.42.23.1" "4242420002" "10.42.23.2" \
  "to_as4" "10.42.34.2" "4242420004" "10.42.34.1"

write_bird_config "${AS4}" "172.20.4.1" "4242420004" \
  "to_as3" "10.42.34.1" "4242420003" "10.42.34.2" \
  "to_as1" "10.42.41.2" "4242420001" "10.42.41.1"

section "Wait for BGP over veth and WireGuard"
wait_for_bgp "${AS1}" 2
wait_for_bgp "${AS2}" 2
wait_for_bgp "${AS3}" 2
wait_for_bgp "${AS4}" 2
run ip netns exec "${AS2}" birdc -s "$(bird_socket "${AS2}")" show protocols
run ip netns exec "${AS3}" birdc -s "$(bird_socket "${AS3}")" show protocols

section "Verify service loopback routing across WireGuard"
wait_for_route "${AS1}" "172.20.3.1"
run ip -n "${AS1}" route get 172.20.3.1 from 172.20.1.1
run ip -n "${AS2}" route get 172.20.3.1 from 172.20.2.1
run ip -n "${AS3}" route get 172.20.1.1 from 172.20.3.1
run ip netns exec "${AS1}" ping -c 2 -W 1 -I 172.20.1.1 172.20.3.1
run ip netns exec "${AS2}" wg show wg23

section "Rollback"
logged_cleanup
run bash -c "ip netns list | grep -E '^(${AS1}|${AS2}|${AS3}|${AS4})( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces, WireGuard keys, and BIRD state removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
