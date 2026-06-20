# Pocket Internet WireGuard Link

## Lab Metadata

```yaml
experiment_id: experiments/labs/pocket-internet-wireguard-link
status: validated
safety_level: tunnel-lab
chapter: docs/part-01-first-principles/10-bgp-over-wireguard.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - bird2
  - birdc
  - wireguard-tools
  - ping
setup_assumptions:
  - temporary namespace names pocket-as1 through pocket-as4 are available
  - BIRD 2, birdc, WireGuard kernel support, and wg tooling are available
cleanup_guarantees:
  - stops all lab-scoped BIRD processes
  - deletes all pocket-as* namespaces named by the lab
  - removes WireGuard interfaces, veth interfaces, keys, and temporary BIRD files
expected_state:
  - four BGP-speaking namespaces
  - AS2-AS3 link carried over WireGuard overlay
  - BGP established across the WireGuard link
  - service-loopback routes remain reachable across the tunnel
  - no service listeners
validation_commands:
  - bash -n experiments/labs/pocket-internet-wireguard-link/run.sh
  - experiments/labs/pocket-internet-wireguard-link/run.sh
  - ip netns list | grep -E 'pocket-as[1-4]' returns no match after cleanup
transcript: experiments/transcripts/pocket-internet-wireguard-link-20260618T112938Z.txt
technical_review:
  required: true
  status: deferred
```

This lab validates the WireGuard-as-link chapter for Pocket Internet.

It builds the four-namespace Pocket Internet ring with BIRD/BGP, but replaces
the AS2-AS3 routed link with a WireGuard tunnel. A separate underlay veth link
carries encrypted WireGuard packets between `pocket-as2` and `pocket-as3`.

The lab proves:

- WireGuard keys and peers are configured manually with `wg` and `ip`.
- A handshake occurs over the underlay.
- BGP runs over the WireGuard overlay link.
- Service loopback reachability still works through BGP-learned routes.
- Rollback removes namespaces, WireGuard interfaces, keys, and temporary files.

Run from the repository root inside the Linux lab environment:

```sh
experiments/labs/pocket-internet-wireguard-link/run.sh
```

Requirements:

- Linux network namespaces
- root privileges
- BIRD 2 and `birdc`
- WireGuard kernel support
- `wireguard-tools`
- `iproute2`

The script records a transcript under ignored `experiments/transcripts/local/` by default.
