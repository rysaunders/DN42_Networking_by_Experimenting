# Local Link Observation

## Lab Metadata

```yaml
experiment_id: experiments/labs/local-link-observation
status: draft
safety_level: local-lab
chapter: docs/part-01-first-principles/11-local-link-observation.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - tcpdump
  - ping
setup_assumptions:
  - temporary namespace names pocket-link-a and pocket-link-b are available
  - tcpdump is installed in the Linux lab environment
cleanup_guarantees:
  - deletes both local-link namespaces
  - removes the veth link with the namespaces
  - removes temporary packet-capture files
expected_state:
  - two namespaces connected by one veth pair
  - one connected /30 route in each namespace
  - ARP neighbor entries appear after first packet exchange
  - tcpdump capture shows ARP and ICMP evidence
  - no daemon processes or service listeners
validation_commands:
  - bash -n experiments/labs/local-link-observation/run.sh
  - experiments/labs/local-link-observation/run.sh
  - ip netns list | grep -E 'pocket-link-(a|b)' returns no match after cleanup
transcript: "pending; OrbStack validation blocked by VM start timeout"
technical_review:
  required: false
  status: not_required
```

This lab validates the local-link discovery and packet-observation chapter.

It creates two temporary namespaces, connects them with one veth pair, observes
route lookup, ARP neighbor state, and packet capture, then rolls everything
back.

Run from the repository root on Linux:

```sh
bash experiments/labs/local-link-observation/run.sh
```

Run from macOS with OrbStack:

```sh
orb bash experiments/labs/local-link-observation/run.sh
```
