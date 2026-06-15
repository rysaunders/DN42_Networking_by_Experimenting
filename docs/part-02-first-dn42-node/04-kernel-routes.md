# Kernel Routes

## Concept

BIRD can know routes that Linux does not use for forwarding until they are exported to the kernel.

## Why It Matters

Seeing a route in BIRD does not prove packets will follow it. The kernel forwarding table is the next boundary.

## Lab / Experiment

Draft: compare selected BIRD routes with installed Linux kernel routes.

## Expected Observations

- BIRD route state and kernel route state can differ.
- Next-hop reachability affects route installation.
- `ip route get` proves the route selected by Linux.

## Troubleshooting Notes

- Check the BIRD kernel protocol.
- Check filters.
- Check next-hop reachability.
- Check route table and rule selection.

## How the Real Internet Does This

Routers maintain control-plane route information and install selected routes into a forwarding table.

## References

- `bird-docs`
- `linux-ip-route`
