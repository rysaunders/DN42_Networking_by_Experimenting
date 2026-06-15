# DN42 WireGuard Examples Review

Reviewed on: 2026-06-15

Primary sources:

- `dn42-wireguard`: https://dn42.cc/wiki/howto/tunnel/wireguard/
- `wireguard-quickstart`: https://www.wireguard.com/quickstart/
- `wireguard-wgquick`: https://man7.org/linux/man-pages/man8/wg-quick.8.html
- `wireguard-netns`: https://www.wireguard.com/netns/
- `dn42-network-settings`: https://dn42.cc/wiki/howto/network-settings/

Local ignored cache:

- `research/cache/dn42-wireguard.html`
- `research/cache/wireguard-quickstart.html`
- `research/cache/wireguard-man-wgquick.html`
- `research/cache/wireguard-netns.html`
- `research/cache/dn42-network-settings.html`

## What This Review Covers

This note records the current DN42 WireGuard tunnel expectations, peer configuration fields, MTU guidance, and tool-specific caveats needed before drafting tunnel experiments.

Use this source set for:

- WireGuard key generation and peer key exchange.
- DN42-specific one-interface-per-peering expectations.
- Endpoint, `AllowedIPs`, keepalive, and MTU guidance.
- `wg`/`ip`, `wg-quick`, and `systemd-networkd` differences.
- Dynamic DNS and network-settings warnings that affect tunnels.

Do not use this source set alone for:

- Peer-specific endpoint policy.
- Firewall rules for a production router.
- NetworkManager, NixOS, OpenWRT, or router-vendor examples without a separate source review.
- Final MTU values without measuring the actual path to a peer.

## Peer Model

DN42 treats WireGuard as a point-to-point tunnel for BGP peering. Although WireGuard can support multiple peers on one interface, the DN42 WireGuard page says to use one interface per peering so BGP, not WireGuard's internal key-based routing, makes routing decisions.

For first experiments, use:

- One WireGuard interface per DN42 peer.
- One local private key per interface or node policy.
- The peer's public key in the local `[Peer]` section.
- Optional preshared key only when both peers agree.
- BGP on top of the tunnel after link testing succeeds.

## Key Guidance

Each side generates its own private key and derives a public key:

```sh
wg genkey | tee privatekey | wg pubkey > publickey
```

Teaching warnings:

- The private key stays local and should be file-permission protected.
- Exchange only public keys with peers.
- If a tunnel handshakes fail, mismatched public keys are a primary debugging target.
- Optional `PresharedKey` adds another shared secret, but it must be coordinated by both peers.

## Endpoint Guidance

At least one peer must provide an `Endpoint = host-or-ip:port` so the first packet has a destination. Static public endpoints are simplest for first experiments.

Dynamic endpoint notes:

- WireGuard resolves endpoint hostnames on start.
- The DN42 page points to WireGuard's `reresolve-dns.sh` pattern for dynamic DNS endpoints.
- Dynamic DNS examples should be treated as a later reliability exercise, not the first tunnel bring-up.

## AllowedIPs Guidance

For plain `wg`/`ip` examples, DN42 currently shows:

```ini
AllowedIPs = 0.0.0.0/0,::/0
```

The page then warns that `AllowedIPs` must include full DN42 ranges, not only the peer next-hop IPs. At minimum, first-node examples should include:

- `172.20.0.0/14` for DN42 IPv4, if using IPv4.
- `fd00::/8` for DN42 IPv6.
- Link-local ranges when link-local IPv6 peering is used.

Important distinction:

- In WireGuard itself, `AllowedIPs` is a cryptokey-routing and data-plane selector.
- In DN42, BGP should make route selection.
- In `wg-quick`, `AllowedIPs` also drives automatic host routes, table routes, and default-route policy unless disabled.

For `wg-quick` examples, DN42 requires `Table = off` when using broad `AllowedIPs`; otherwise the host may route clearnet/default traffic through a DN42 peer and lose connectivity.

## Keepalive Guidance

The DN42 WireGuard page does not show `PersistentKeepalive`, but the official WireGuard quickstart explains when to use it:

- Default is off.
- Use it when a peer is behind NAT or a stateful firewall and must remain reachable while otherwise idle.
- The common interval is 25 seconds.

Book default:

- Include `PersistentKeepalive = 25` in examples only on the side behind NAT or when the learner needs to keep an idle mapping open.
- Do not present keepalive as mandatory for every tunnel.

## MTU Guidance

The DN42 page recommends testing the path MTU to the peer endpoint, for example with a large ping, then subtracting 80 from the discovered outer-path MTU and setting the WireGuard interface MTU manually.

Teaching default:

- Do not hard-code a universal DN42 WireGuard MTU.
- Add an MTU measurement experiment before final tunnel configuration.
- If `wg-quick` is used, explain that its manual `MTU` field overrides automatic MTU discovery.
- Keep anycast MTU warnings from `dn42-network-settings` separate from basic point-to-point tunnel MTU.

## Tool and Distro Differences

### Plain `wg` and `ip`

The DN42 page's lowest-level path is:

- `ip link add dev <interface> type wireguard`
- `wg setconf <interface> tunnel.conf`
- add link-local IPv6 and/or point-to-point IPv4 addresses with `ip addr`
- `ip link set <interface> up`

This is the clearest first experiment because it keeps routes under explicit BGP control.

### `wg-quick`

`wg-quick` is convenient but needs DN42-specific guardrails:

- It is designed for simple needs; advanced setups should use `wg`/`ip` or a network manager directly.
- It infers routes from peer `AllowedIPs`.
- It treats `0.0.0.0/0` and `::/0` as default-route intent.
- Use `Table = off` for DN42 tunnel examples where BGP controls routing.
- DN42 point-to-point `/32` and `/128` peer addressing needs `PostUp` commands.
- Use `which ip` or a known absolute path when writing `PostUp` examples.

### `systemd-networkd`

The DN42 page includes `systemd-networkd` examples using:

- `.netdev` for `[NetDev]`, `[WireGuard]`, and `[WireGuardPeer]`.
- `.network` for `DHCP=no`, `IPv6AcceptRA=false`, `IPForward=yes`, and `IPv4ReversePathFilter=no`.
- `KeepConfiguration=yes` on networkd 244 or newer.
- `CriticalConnection=true` for older networkd behavior.
- `[Address]` sections with `Peer=` for point-to-point IPv4 and IPv6.

Use this as a later distro-specific exercise. Do not mix it into the first plain `wg`/`ip` chapter.

### NetworkManager, NixOS, OpenWRT, and Router OSes

The current reviewed DN42 WireGuard page does not provide complete examples for these. Any book examples for them need separate source review and should not be inferred from the Linux `wg`/`ip`, `wg-quick`, or `systemd-networkd` snippets.

## Adjacent Network Settings

From the DN42 network settings page:

- Disable IPv4 reverse path filtering for asymmetric DN42 routing.
- Enable IPv4 and IPv6 forwarding.
- Avoid dropping forwarded traffic solely because conntrack marks it invalid in asymmetric routing cases.
- Be careful when using DN42 IPs as BGP peer addresses if not using extended next hop and if the same IP is used for services.

These settings should be verified before diagnosing WireGuard or BGP as broken.

## Stale or Risky Examples to Flag

- `AllowedIPs = 0.0.0.0/0,::/0` is acceptable only when routing side effects are controlled; in `wg-quick`, use `Table = off`.
- `AllowedIPs` containing only next-hop addresses is wrong for DN42 transit because WireGuard will reject data-plane destinations outside those selectors.
- A peer endpoint hostname may become stale unless re-resolved or the interface is restarted.
- A single interface with multiple DN42 peers conflicts with the current DN42 guidance that BGP should handle routing per peering.
- MTU values must be measured per path; examples with fixed MTU values should be treated as placeholders.

## Open Questions Before Chapter Drafting

- Decide whether the first tunnel experiment is IPv6 link-local only, IPv4 point-to-point, or both.
- Decide whether first examples use plain `wg`/`ip` only, then introduce `wg-quick` as a convenience with caveats.
- Build a local fixture that checks generated `wg` and `wg-quick strip` output without requiring real private keys.
- Review NetworkManager, NixOS, and OpenWRT sources only when those examples become chapter targets.
