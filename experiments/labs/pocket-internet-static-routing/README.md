# Pocket Internet Static Routing Lab

## Lab Metadata

```yaml
experiment_id: experiments/labs/pocket-internet-static-routing
status: validated
safety_level: local-lab
chapter: docs/part-01-first-principles/03-pocket-internet-static-routing.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - ping
setup_assumptions:
  - temporary namespace names pocket-as1 through pocket-as4 are available
  - host allows Linux network namespace creation
cleanup_guarantees:
  - deletes all pocket-as* namespaces named by the lab
  - removes veth interfaces and service loopbacks with their namespaces
expected_state:
  - four namespaces: pocket-as1, pocket-as2, pocket-as3, pocket-as4
  - square of point-to-point veth links
  - service loopbacks 172.20.1.1/32 through 172.20.4.1/32
  - static routes for remote service loopbacks
  - no daemon processes or listeners
validation_commands:
  - bash -n experiments/labs/pocket-internet-static-routing/run.sh
  - experiments/labs/pocket-internet-static-routing/run.sh
  - ip netns list | grep -E 'pocket-as[1-4]' returns no match after cleanup
transcript: experiments/transcripts/pocket-internet-static-routing-20260616T192307Z.txt
technical_review:
  required: false
  status: not_required
```

This lab builds a disposable four-AS Pocket Internet topology with Linux network namespaces:

- `pocket-as1`
- `pocket-as2`
- `pocket-as3`
- `pocket-as4`

The namespaces form a square. Each namespace has point-to-point veth links, a loopback service address, forwarding enabled, and static routes for remote service addresses.

The lab demonstrates:

- AS-shaped namespaces,
- veth links as local point-to-point links,
- loopback addresses as stable service addresses,
- static route lookup across multiple hops,
- end-to-end ping between service addresses,
- packet counter evidence on transit links,
- link failure with no automatic reroute,
- manual route repair through the alternate path,
- rollback that removes namespaces and veth state.

## Before Running

- Linux is required because this lab uses Linux network namespaces.
- `iproute2` is required for the `ip` command.
- Root privileges are required; the script uses `sudo` when it is not already running as root.
- macOS users should run the lab inside an OrbStack Linux machine.
- The transcript is written under ignored `experiments/transcripts/local/` by default.

Run from the repository root on a Linux host or OrbStack Linux machine:

```sh
bash experiments/labs/pocket-internet-static-routing/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/pocket-internet-static-routing/run.sh
```

The script uses `sudo` for namespace operations when it is not already running as root. It writes a transcript to ignored `experiments/transcripts/local/` by default.
