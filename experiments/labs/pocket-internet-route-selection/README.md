# Pocket Internet Route Selection

## Lab Metadata

```yaml
experiment_id: experiments/labs/pocket-internet-route-selection
status: validated
safety_level: local-lab
chapter: docs/part-01-first-principles/04-routing-tables.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
setup_assumptions:
  - temporary namespace name pocket-rs-edge is available
  - dummy interface support is available
cleanup_guarantees:
  - deletes namespace pocket-rs-edge
  - removes dummy interfaces and temporary routes with the namespace
expected_state:
  - one namespace: pocket-rs-edge
  - dummy interfaces for competing exits
  - overlapping /32, /24, /16, and default routes
  - no daemon processes or listeners
validation_commands:
  - bash -n experiments/labs/pocket-internet-route-selection/run.sh
  - experiments/labs/pocket-internet-route-selection/run.sh
  - ip netns list | grep -q pocket-rs-edge returns no match after cleanup
transcript: experiments/transcripts/pocket-internet-route-selection-20260616T185554Z.txt
technical_review:
  required: false
  status: not_required
```

This lab validates the route-selection chapter.

It creates one temporary namespace, `pocket-rs-edge`, with two dummy interfaces:

- `edge-transit0`
- `edge-service0`

The lab installs overlapping routes and uses `ip route get` to prove that the
more-specific route wins. It then removes the more-specific route and shows
fallback to the broader route.

Run from the repository root on Linux:

```sh
bash experiments/labs/pocket-internet-route-selection/run.sh
```

Run from macOS with OrbStack:

```sh
orb bash experiments/labs/pocket-internet-route-selection/run.sh
```
