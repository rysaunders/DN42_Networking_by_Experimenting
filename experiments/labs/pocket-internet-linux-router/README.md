# Pocket Internet Linux Router Lab

## Lab Metadata

```yaml
experiment_id: experiments/labs/pocket-internet-linux-router
status: validated
safety_level: local-lab
chapter: docs/part-01-first-principles/01-linux-networking.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - ping
setup_assumptions:
  - temporary namespace names pocket-left, pocket-router, and pocket-right are available
  - host allows Linux network namespace creation
cleanup_guarantees:
  - deletes all pocket-left, pocket-router, and pocket-right namespaces
  - removes veth interfaces with their namespaces
expected_state:
  - three namespaces: pocket-left, pocket-router, pocket-right
  - two veth links: left-router and router-right
  - connected /30 routes plus explicit edge return routes
  - forwarding enabled only inside pocket-router
  - no daemon processes or listeners
validation_commands:
  - bash -n experiments/labs/pocket-internet-linux-router/run.sh
  - experiments/labs/pocket-internet-linux-router/run.sh
  - ip netns list | grep -E 'pocket-(left|router|right)' returns no match after cleanup
transcript: experiments/transcripts/pocket-internet-linux-router-20260617T183713Z.txt
technical_review:
  required: false
  status: not_required
```

This lab builds a disposable three-node IPv4 network with Linux network namespaces:

- `pocket-left`
- `pocket-router`
- `pocket-right`

The middle namespace forwards traffic between the two edge namespaces. The lab demonstrates:

- isolated namespace setup,
- route lookup before packet forwarding,
- the difference between having a route and having forwarding enabled,
- forwarding through a Linux router namespace,
- rollback that removes namespaces and veth state.

## Before Running

- Linux is required because this lab uses Linux network namespaces.
- `iproute2` is required for the `ip` command.
- Root privileges are required to create namespaces and veth interfaces.
- The script uses `sudo` when it is not already running as root.
- macOS users should run the lab inside an OrbStack Linux machine.
- The transcript is written under ignored `experiments/transcripts/local/` by default.

Run from the repository root on a Linux host or OrbStack Linux machine:

```sh
bash experiments/labs/pocket-internet-linux-router/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/pocket-internet-linux-router/run.sh
```
