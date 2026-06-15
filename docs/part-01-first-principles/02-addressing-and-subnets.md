# Addresses and Subnets

## Concept

IP prefixes describe sets of addresses. Forwarding uses the most specific matching route.

## Why It Matters

DN42 uses IPv4 and IPv6 prefixes, and route filters often depend on prefix ownership, prefix length, and origin ASN.

## Lab / Experiment

Draft: add overlapping routes in a local namespace and observe longest-prefix match with `ip route get`.

## Expected Observations

- A more-specific route wins over a less-specific route.
- Removing the more-specific route falls back to the broader route.
- Source address choice can differ from destination route choice.

## Troubleshooting Notes

- If traffic uses the wrong route, compare all matching prefixes.
- If replies fail, inspect the source address as well as the destination route.

## How the Real Internet Does This

BGP advertises prefixes. Routers install selected routes, then forward packets using destination prefix lookup.

## References

- `rfc-4193`
- `linux-ip-route`
