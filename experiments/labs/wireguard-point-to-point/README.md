# WireGuard Point-to-Point

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
