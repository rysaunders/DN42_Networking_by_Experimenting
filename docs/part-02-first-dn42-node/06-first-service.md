# First Service

!!! warning "Later draft - not implementation-ready"
    This page is roadmap material. Current DN42 service, firewall, source-address, return-path, and exposure guidance must be refreshed before release.

## Concept

A reachable service proves more than a route exists. It proves forward path, return path, source address, firewall, and application binding are aligned.

## Why It Matters

The goal is not only to see BGP routes. The goal is to make a small network carry useful traffic safely.

## Lab / Experiment

Draft: reach a known DN42 service, then run a minimal service on the reader's own DN42 prefix.

## Expected Observations

- A known DN42 service responds.
- Local service binds to the intended DN42 address.
- Return traffic uses the expected route.

## Troubleshooting Notes

- If the route exists but the service fails, check source address and firewall.
- If local testing works but remote testing fails, check return path and export policy.
- If the service binds to the wrong address, fix application or systemd unit configuration.

## How the Real Internet Does This

Service reachability depends on routing, DNS, host firewalling, application binding, and operations.

## References

- `dn42-getting-started`
