# Pocket Internet WireGuard Link

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

The script records a transcript under `experiments/transcripts/`.
