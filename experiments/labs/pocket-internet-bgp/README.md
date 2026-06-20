# Pocket Internet BGP

## Lab Metadata

```yaml
experiment_id: experiments/labs/pocket-internet-bgp
status: validated
safety_level: local-routing-daemon
chapter: docs/part-01-first-principles/06-bgp-before-dn42.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - bird2
  - birdc
  - ping
setup_assumptions:
  - temporary namespace names pocket-as1 through pocket-as4 are available
  - BIRD 2 and birdc are installed in the Linux environment
cleanup_guarantees:
  - stops all lab-scoped BIRD processes
  - deletes all pocket-as* namespaces named by the lab
  - removes temporary BIRD config, socket, and PID files
expected_state:
  - four namespaces: pocket-as1 through pocket-as4
  - BIRD sessions between neighboring AS namespaces
  - service loopback routes exchanged by BGP
  - route withdrawal after an isolated link
  - no service listeners
validation_commands:
  - bash -n experiments/labs/pocket-internet-bgp/run.sh
  - experiments/labs/pocket-internet-bgp/run.sh
  - ip netns list | grep -E 'pocket-as[1-4]' returns no match after cleanup
transcript: experiments/transcripts/pocket-internet-bgp-20260617T191953Z.txt
technical_review:
  required: true
  status: deferred
```

This lab validates the BIRD/BGP chapter for Pocket Internet.

It builds the four-namespace Pocket Internet ring, starts one BIRD instance per
namespace, establishes local BGP sessions between different lab AS numbers over
veth links, advertises service loopback addresses, exports selected BGP routes
into the Linux kernel, and then isolates one AS to observe route withdrawal and
convergence.

Run from the repository root inside the Linux lab environment:

```sh
experiments/labs/pocket-internet-bgp/run.sh
```

Requirements:

- Linux network namespaces
- root privileges
- BIRD 2 and `birdc`
- `iproute2`

The script records a transcript under ignored `experiments/transcripts/local/` by default.
