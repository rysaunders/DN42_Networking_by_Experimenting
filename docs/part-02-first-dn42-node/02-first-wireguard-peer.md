# First WireGuard Peer

!!! warning "Later draft - not implementation-ready"
    This page is roadmap material. Current DN42 WireGuard peer expectations, MTU guidance, `rp_filter` behavior, asymmetric-routing caveats, firewall behavior, and rollback checks must be refreshed before release.

    Before this becomes an implementation chapter, it must satisfy the [mandatory border checklist](../pocket-internet-dn42-interconnect.md#mandatory-border-checklist).

## Concept

A DN42 WireGuard peer creates the tunnel link used by BGP.

## Why It Matters

BGP needs a working transport path before route exchange can succeed.

## Lab / Experiment

Draft: configure one WireGuard peer from current peer-provided parameters.

## Expected Observations

- `wg show` reports a recent handshake.
- DN42 peer addresses route through the WireGuard interface.
- Public Internet traffic still uses the normal default route.

## Troubleshooting Notes

- Check keys, endpoint, listen port, NAT, firewall, and MTU.
- Verify route lookup before testing with application traffic.
- Verify `rp_filter`, asymmetric routing, and firewall behavior against current DN42 guidance before publishing commands. Do not copy host-wide sysctl changes from examples without technical review.

## How the Real Internet Does This

Physical or logical links connect routers. In DN42, WireGuard often provides that logical link across the public Internet.

## References

- `wireguard-quickstart`
- `dn42-getting-started`
