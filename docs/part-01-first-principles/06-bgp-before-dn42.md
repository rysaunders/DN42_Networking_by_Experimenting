# BGP Before DN42

## Concept

BGP exchanges network reachability between autonomous systems.

## Why It Matters

DN42 uses BGP to tell peers which prefixes are reachable and which path attributes describe those routes.

## Lab / Experiment

Draft: run a local BIRD-to-BIRD session between two lab routers before configuring a public DN42 peer.

## Expected Observations

- A BGP session moves through states before reaching Established.
- Routes can exist in BIRD without being installed into the Linux kernel.
- Import and export policy determine what is accepted and announced.

## Troubleshooting Notes

- Active or Connect state often points to neighbor address, TCP, or firewall issues.
- Established with no routes often points to filters.
- Routes in BIRD but not Linux often point to kernel protocol or next-hop reachability.

## How the Real Internet Does This

Public Internet BGP also exchanges reachability and AS path information, but real networks add policy, validation, contracts, and operational controls.

## References

- `rfc-4271`
- `bird-docs`
