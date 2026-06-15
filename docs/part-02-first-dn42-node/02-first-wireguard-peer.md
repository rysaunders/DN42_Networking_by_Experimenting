# First WireGuard Peer

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

## How the Real Internet Does This

Physical or logical links connect routers. In DN42, WireGuard often provides that logical link across the public Internet.

## References

- `wireguard-quickstart`
- `dn42-getting-started`
