#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="pocket-internet-static-routing"

AS1="pocket-as1"
AS2="pocket-as2"
AS3="pocket-as3"
AS4="pocket-as4"

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
  ip netns delete "${AS1}" >/dev/null 2>&1
  ip netns delete "${AS2}" >/dev/null 2>&1
  ip netns delete "${AS3}" >/dev/null 2>&1
  ip netns delete "${AS4}" >/dev/null 2>&1
}

trap cleanup EXIT

section "Environment"
run uname -a
run ip -V
run id
printf '\nTranscript: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"

section "Rollback before setup"
cleanup
run bash -c "ip netns list | grep -E '^(${AS1}|${AS2}|${AS3}|${AS4})( |$)' || true"

section "Create AS-shaped namespaces"
run ip netns add "${AS1}"
run ip netns add "${AS2}"
run ip netns add "${AS3}"
run ip netns add "${AS4}"
run ip netns list

section "Create veth links"
run ip link add as1-as2 type veth peer name as2-as1
run ip link set as1-as2 netns "${AS1}"
run ip link set as2-as1 netns "${AS2}"

run ip link add as2-as3 type veth peer name as3-as2
run ip link set as2-as3 netns "${AS2}"
run ip link set as3-as2 netns "${AS3}"

run ip link add as3-as4 type veth peer name as4-as3
run ip link set as3-as4 netns "${AS3}"
run ip link set as4-as3 netns "${AS4}"

run ip link add as4-as1 type veth peer name as1-as4
run ip link set as4-as1 netns "${AS4}"
run ip link set as1-as4 netns "${AS1}"

section "Configure loopback service addresses"
run ip -n "${AS1}" addr add 172.20.1.1/32 dev lo
run ip -n "${AS2}" addr add 172.20.2.1/32 dev lo
run ip -n "${AS3}" addr add 172.20.3.1/32 dev lo
run ip -n "${AS4}" addr add 172.20.4.1/32 dev lo

section "Configure point-to-point link addresses"
run ip -n "${AS1}" addr add 10.42.12.1/30 dev as1-as2
run ip -n "${AS2}" addr add 10.42.12.2/30 dev as2-as1

run ip -n "${AS2}" addr add 10.42.23.1/30 dev as2-as3
run ip -n "${AS3}" addr add 10.42.23.2/30 dev as3-as2

run ip -n "${AS3}" addr add 10.42.34.1/30 dev as3-as4
run ip -n "${AS4}" addr add 10.42.34.2/30 dev as4-as3

run ip -n "${AS4}" addr add 10.42.41.1/30 dev as4-as1
run ip -n "${AS1}" addr add 10.42.41.2/30 dev as1-as4

section "Bring links up"
for ns in "${AS1}" "${AS2}" "${AS3}" "${AS4}"; do
  run ip -n "${ns}" link set lo up
done

run ip -n "${AS1}" link set as1-as2 up
run ip -n "${AS1}" link set as1-as4 up
run ip -n "${AS2}" link set as2-as1 up
run ip -n "${AS2}" link set as2-as3 up
run ip -n "${AS3}" link set as3-as2 up
run ip -n "${AS3}" link set as3-as4 up
run ip -n "${AS4}" link set as4-as3 up
run ip -n "${AS4}" link set as4-as1 up

section "Enable forwarding in every AS namespace"
for ns in "${AS1}" "${AS2}" "${AS3}" "${AS4}"; do
  run ip netns exec "${ns}" sysctl -w net.ipv4.ip_forward=1
done

section "Show connected routes"
run ip -n "${AS1}" route
run ip -n "${AS2}" route
run ip -n "${AS3}" route
run ip -n "${AS4}" route

section "Route lookup before static service routes"
run ip -n "${AS1}" route get 172.20.3.1 || true
run ip netns exec "${AS1}" ping -c 1 -W 1 -I 172.20.1.1 172.20.3.1 || true

section "Install clockwise static service routes"
run ip -n "${AS1}" route add 172.20.3.1/32 via 10.42.12.2 dev as1-as2
run ip -n "${AS2}" route add 172.20.3.1/32 via 10.42.23.2 dev as2-as3
run ip -n "${AS3}" route add 172.20.1.1/32 via 10.42.23.1 dev as3-as2
run ip -n "${AS2}" route add 172.20.1.1/32 via 10.42.12.1 dev as2-as1

section "Predict and inspect the selected path"
run ip -n "${AS1}" route get 172.20.3.1 from 172.20.1.1
run ip -n "${AS2}" route get 172.20.3.1
run ip -n "${AS3}" route get 172.20.1.1 from 172.20.3.1

section "Ping service loopbacks through static routes"
run ip netns exec "${AS1}" ping -c 2 -W 1 -I 172.20.1.1 172.20.3.1

section "Observe transit packet counters"
run ip -n "${AS2}" -s link show as2-as1
run ip -n "${AS2}" -s link show as2-as3

section "Break the selected AS2-AS3 link"
run ip -n "${AS2}" link set as2-as3 down
run ip -n "${AS1}" route get 172.20.3.1 from 172.20.1.1
run ip netns exec "${AS1}" ping -c 1 -W 1 -I 172.20.1.1 172.20.3.1 || true

section "Show the alternate physical path exists"
run ip -n "${AS1}" route get 10.42.41.1
run ip -n "${AS4}" route get 10.42.34.1
run ip -n "${AS3}" route get 10.42.34.2

section "Repair reachability by changing static routes"
run ip -n "${AS1}" route replace 172.20.3.1/32 via 10.42.41.1 dev as1-as4
run ip -n "${AS4}" route add 172.20.3.1/32 via 10.42.34.1 dev as4-as3
run ip -n "${AS3}" route replace 172.20.1.1/32 via 10.42.34.2 dev as3-as4
run ip -n "${AS4}" route add 172.20.1.1/32 via 10.42.41.2 dev as4-as1

section "Verify repaired path through AS4"
run ip -n "${AS1}" route get 172.20.3.1 from 172.20.1.1
run ip -n "${AS4}" route get 172.20.3.1
run ip netns exec "${AS1}" ping -c 2 -W 1 -I 172.20.1.1 172.20.3.1
run ip -n "${AS4}" -s link show as4-as1
run ip -n "${AS4}" -s link show as4-as3

section "Rollback"
cleanup
run bash -c "ip netns list | grep -E '^(${AS1}|${AS2}|${AS3}|${AS4})( |$)' || true"

trap - EXIT

section "Result"
printf 'Lab complete. Temporary namespaces removed.\n'
printf 'Transcript saved to: %s\n' "${LAB_TRANSCRIPT_PATH:-not-set}"
