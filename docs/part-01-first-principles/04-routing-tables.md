# Routing Tables

## Concept

Linux can use multiple routing tables and rules. The main table is only part of the lookup story.

## Why It Matters

DN42 labs often need to prove that DN42 traffic uses the overlay while public Internet traffic stays on the normal route.

## Lab / Experiment

Draft: compare `ip route`, `ip rule`, and `ip route get` while adding temporary routes and rules.

## Expected Observations

- `ip route get` shows the selected route for a destination.
- Custom tables can change lookup results when selected by rules.
- Blackhole or unreachable routes can make failures explicit.

## Troubleshooting Notes

- If `ip route` and actual behavior disagree, inspect `ip rule`.
- If a route exists but is not selected, inspect priority and prefix specificity.

## How the Real Internet Does This

Routers separate route selection from forwarding. Linux exposes this through route tables, rules, and kernel route installation.

## References

- `linux-ip-route`
