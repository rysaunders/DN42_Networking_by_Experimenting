# Linux as a Router

## Concept

A Linux system can route packets when it has multiple interfaces, suitable addresses, route entries, and forwarding enabled.

## Why It Matters

DN42 nodes are routers. If Linux forwarding, local routes, or firewall policy are unclear, BGP and WireGuard errors become difficult to diagnose.

## Lab / Experiment

Draft: create isolated network namespaces and route between them.

## Expected Observations

- Interfaces have addresses.
- Connected routes appear automatically.
- Forwarded packets require forwarding to be enabled.
- Route lookup predicts packet path before `ping` runs.

## Troubleshooting Notes

- If the router can ping both sides but hosts cannot ping through it, check forwarding.
- If route lookup is correct but packets disappear, check firewall counters.
- If no connected route exists, check interface state and address prefix length.

## How the Real Internet Does This

Routers forward by table lookup. They do not forward because they are generally connected to the Internet.

## References

- `linux-ip-route`
