# Addresses, Prefixes, and Longest Match Lab

## Lab Metadata

```yaml
experiment_id: experiments/labs/addresses-longest-match
status: validated
safety_level: local-lab
chapter: docs/part-01-first-principles/02-addressing-and-subnets.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
setup_assumptions:
  - temporary namespace name pocket-addrmatch is available
  - required iproute2 commands are installed
cleanup_guarantees:
  - deletes namespace pocket-addrmatch
  - removes lab-only interfaces and routes with the namespace
expected_state:
  - one namespace: pocket-addrmatch
  - dummy interfaces: exact0, service0, site0, internet0
  - overlapping routes for longest-prefix route lookup
  - no daemon processes or listeners
validation_commands:
  - bash -n experiments/labs/addresses-longest-match/run.sh
  - experiments/labs/addresses-longest-match/run.sh
  - ip netns list | grep -q pocket-addrmatch returns no match after cleanup
transcript: experiments/transcripts/addresses-longest-match-20260616T124649Z.txt
technical_review:
  required: false
  status: not_required
```

This lab creates one disposable Linux network namespace and installs overlapping routes to show longest-prefix match.

Overlapping routes means more than one route could match the same destination. This lab observes which route Linux would choose; it does not build real neighbors behind the fake next hops.

The lab demonstrates:

- an address as one point,
- a prefix as a set of addresses,
- `/16`, `/24`, and `/32` route specificity,
- default route fallback,
- `ip route get` as a prediction tool,
- route fallback after deleting more-specific routes,
- rollback that removes the namespace and temporary routes.

## Before Running

- Linux is required because this lab uses Linux network namespaces.
- `iproute2` is required for the `ip` command.
- Root privileges are required; the script uses `sudo` when it is not already running as root.
- macOS users should run the lab inside an OrbStack Linux machine.
- The transcript is written under ignored `experiments/transcripts/local/` by default.

Run from the repository root on a Linux host or OrbStack Linux machine:

```sh
bash experiments/labs/addresses-longest-match/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/addresses-longest-match/run.sh
```
