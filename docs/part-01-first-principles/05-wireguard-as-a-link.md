# WireGuard as a Link

## Concept

WireGuard creates an encrypted overlay interface between peers over an existing underlay network.

## Why It Matters

Most DN42 peers are not physically connected. A tunnel behaves like a link for routing, while packets still cross the public Internet underneath.

## Lab / Experiment

Draft: connect two local namespaces with WireGuard and observe both underlay and overlay traffic.

## Expected Observations

- WireGuard peers have keys.
- A current handshake indicates the tunnel is alive.
- Overlay addresses route through the WireGuard interface.
- Public Internet routes should not silently move into the tunnel.

## Troubleshooting Notes

- No handshake usually means key, endpoint, NAT, or firewall trouble.
- Handshake without payload traffic can mean route or firewall trouble.
- Unexpected default routes can come from overly broad configuration.

## How the Real Internet Does This

Overlay networks build logical links across another network. DN42 commonly uses this pattern for BGP peer links.

## References

- `wireguard-quickstart`
