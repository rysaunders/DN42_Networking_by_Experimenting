# WireGuard Point-to-Point

## Lab Metadata

```yaml
experiment_id: experiments/labs/wireguard-point-to-point
status: validated
safety_level: tunnel-lab
chapter: docs/part-01-first-principles/09-wireguard-as-a-link.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - wireguard-tools
  - ping
setup_assumptions:
  - temporary namespace names pocket-wg-a and pocket-wg-b are available
  - WireGuard kernel support and wg tooling are available
cleanup_guarantees:
  - deletes both WireGuard lab namespaces
  - removes veth underlay interfaces and WireGuard interfaces
  - removes temporary key files
expected_state:
  - two namespaces with a veth underlay
  - two WireGuard overlay interfaces
  - successful handshake and ping across overlay
  - no daemon processes or service listeners
validation_commands:
  - bash -n experiments/labs/wireguard-point-to-point/run.sh
  - experiments/labs/wireguard-point-to-point/run.sh
  - ip netns list | grep -E 'pocket-wg-(a|b)' returns no match after cleanup
transcript: experiments/transcripts/wireguard-point-to-point-20260618T213251Z.txt
technical_review:
  required: true
  status: deferred
```

This lab validates the standalone WireGuard-as-a-link chapter.

It creates two temporary namespaces, connects them with a local veth underlay,
builds a WireGuard overlay link, verifies route lookup and ping across both
layers, inspects `wg show`, then rolls everything back.

The lab proves:

- the underlay veth path works before WireGuard is configured,
- private keys are generated with restrictive permissions,
- WireGuard peers can handshake over a local underlay,
- overlay traffic uses the `wg23` interface,
- rollback removes namespaces, keys, and temporary files.

Run from the repository root inside the Linux lab environment:

```sh
experiments/labs/wireguard-point-to-point/run.sh
```

Requirements:

- Linux network namespaces
- root privileges
- WireGuard kernel support
- `wireguard-tools`
- `iproute2`

The script records a transcript under ignored `experiments/transcripts/local/` by default.
