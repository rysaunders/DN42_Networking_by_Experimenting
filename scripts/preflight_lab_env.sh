#!/usr/bin/env bash
set -uo pipefail

LAB_NS="pocket-preflight-$$"
VETH_A="pp-a-$$"
VETH_B="pp-b-$$"
FAILED=0
WARNED=0
SUDO=()

log() {
  printf '%s\n' "$*"
}

pass() {
  printf 'PASS: %s\n' "$*"
}

warn() {
  WARNED=1
  printf 'WARN: %s\n' "$*"
}

fail() {
  FAILED=1
  printf 'FAIL: %s\n' "$*"
}

run_privileged() {
  "${SUDO[@]}" "$@"
}

cleanup() {
  run_privileged ip netns delete "${LAB_NS}" >/dev/null 2>&1 || true
  run_privileged ip link delete "${VETH_A}" >/dev/null 2>&1 || true
  run_privileged ip link delete "${VETH_B}" >/dev/null 2>&1 || true
}

check_command() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    pass "found ${command_name}: $(command -v "${command_name}")"
    return 0
  fi

  fail "missing ${command_name}"
  return 1
}

choose_privilege_runner() {
  if [[ "${EUID}" -eq 0 ]]; then
    pass "running as root"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    SUDO=(sudo -n)
    pass "not root, but passwordless sudo works"
    return 0
  fi

  if command -v capsh >/dev/null 2>&1 && capsh --print 2>/dev/null | grep -q 'cap_net_admin'; then
    warn "cap_net_admin appears present, but this script still needs namespace operations to succeed"
    return 0
  fi

  fail "need root, passwordless sudo, or enough network capabilities for namespace tests"
  return 1
}

check_iproute2() {
  if ! check_command ip; then
    return
  fi

  if ip -V >/dev/null 2>&1; then
    pass "$(ip -V 2>&1)"
  else
    fail "ip exists but 'ip -V' failed"
  fi

  if ip netns list >/dev/null 2>&1; then
    pass "ip netns is available"
  else
    fail "ip exists but 'ip netns list' failed"
  fi
}

check_namespace() {
  if run_privileged ip netns add "${LAB_NS}" >/dev/null 2>&1; then
    pass "created disposable namespace ${LAB_NS}"
  else
    fail "could not create disposable namespace ${LAB_NS}"
    return 1
  fi

  if run_privileged ip -n "${LAB_NS}" link set lo up >/dev/null 2>&1; then
    pass "brought loopback up inside ${LAB_NS}"
  else
    fail "could not bring loopback up inside ${LAB_NS}"
  fi
}

check_dummy_interface() {
  if run_privileged ip -n "${LAB_NS}" link add preflight-dummy type dummy >/dev/null 2>&1; then
    pass "created dummy interface inside ${LAB_NS}"
  else
    fail "could not create dummy interface inside ${LAB_NS}"
    return
  fi

  if run_privileged ip -n "${LAB_NS}" link delete preflight-dummy >/dev/null 2>&1; then
    pass "deleted dummy interface inside ${LAB_NS}"
  else
    fail "could not delete dummy interface inside ${LAB_NS}"
  fi
}

check_veth_pair() {
  if run_privileged ip link add "${VETH_A}" type veth peer name "${VETH_B}" >/dev/null 2>&1; then
    pass "created disposable veth pair"
  else
    fail "could not create disposable veth pair"
    return
  fi

  if run_privileged ip link set "${VETH_B}" netns "${LAB_NS}" >/dev/null 2>&1; then
    pass "moved one veth endpoint into ${LAB_NS}"
  else
    fail "could not move veth endpoint into ${LAB_NS}"
  fi

  if run_privileged ip link delete "${VETH_A}" >/dev/null 2>&1; then
    pass "deleted disposable veth pair"
  else
    fail "could not delete disposable veth pair"
  fi
}

check_wireguard() {
  if command -v wg >/dev/null 2>&1; then
    pass "$(wg --version 2>&1)"
  else
    warn "wg is not installed; WireGuard labs need wireguard-tools"
  fi

  if run_privileged ip -n "${LAB_NS}" link add preflight-wg type wireguard >/dev/null 2>&1; then
    pass "created WireGuard interface inside ${LAB_NS}"
    if run_privileged ip -n "${LAB_NS}" link delete preflight-wg >/dev/null 2>&1; then
      pass "deleted WireGuard interface inside ${LAB_NS}"
    else
      fail "could not delete WireGuard interface inside ${LAB_NS}"
    fi
  else
    warn "could not create WireGuard interface; WireGuard labs may need kernel/module support"
  fi
}

check_bird() {
  if command -v bird >/dev/null 2>&1; then
    pass "$(bird --version 2>&1)"
  else
    warn "bird is not installed; BIRD/BGP labs need BIRD 2"
  fi

  if command -v birdc >/dev/null 2>&1; then
    pass "found birdc: $(command -v birdc)"
  else
    warn "birdc is not installed; BIRD/BGP labs need birdc"
  fi
}

check_python() {
  if command -v python3 >/dev/null 2>&1; then
    pass "$(python3 --version 2>&1)"
  else
    warn "python3 is not installed; service labs use python3 -m http.server"
  fi
}

main() {
  log "Pocket Internet lab environment preflight"
  log "This script creates one disposable namespace named ${LAB_NS} and removes it before exiting."
  log ""

  check_iproute2
  choose_privilege_runner

  if [[ "${FAILED}" -eq 0 ]]; then
    trap cleanup EXIT
    check_namespace
  fi

  if run_privileged ip netns list 2>/dev/null | grep -q "^${LAB_NS}\b"; then
    check_dummy_interface
    check_veth_pair
    check_wireguard
  else
    warn "skipping interface probes because disposable namespace was not created"
  fi

  check_bird
  check_python

  cleanup
  trap - EXIT

  if run_privileged ip netns list 2>/dev/null | grep -q "^${LAB_NS}\b"; then
    fail "cleanup did not remove ${LAB_NS}"
  else
    pass "cleanup removed ${LAB_NS}"
  fi

  log ""
  if [[ "${FAILED}" -ne 0 ]]; then
    log "Result: failed. Fix FAIL items before running labs."
    exit 1
  fi

  if [[ "${WARNED}" -ne 0 ]]; then
    log "Result: usable with warnings. Some later labs may need extra packages or kernel support."
    exit 0
  fi

  log "Result: ready for current Pocket Internet labs."
}

main "$@"
