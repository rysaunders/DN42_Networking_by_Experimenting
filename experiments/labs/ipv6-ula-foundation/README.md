# IPv6 and ULA Foundation

## Lab Metadata

```yaml
experiment_id: experiments/labs/ipv6-ula-foundation
status: validated
safety_level: local-lab
chapter: docs/part-01-first-principles/12-ipv6-ula-foundation.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - tcpdump
  - ping
setup_assumptions:
  - temporary namespace names pocket-v6-a and pocket-v6-b are available
  - tcpdump is installed in the Linux lab environment
cleanup_guarantees:
  - deletes both IPv6 lab namespaces
  - removes veth, dummy, route, and neighbor state with the namespaces
  - removes temporary packet-capture files
expected_state:
  - two namespaces connected by one IPv6 ULA /64 veth link
  - one service loopback address fd42:4242:200::1/128 inside pocket-v6-b
  - one explicit IPv6 host route from pocket-v6-a to that service loopback
  - NDP neighbor entries appear after first packet exchange
  - tcpdump capture shows ICMPv6 neighbor discovery and echo traffic
  - no daemon processes or service listeners
validation_commands:
  - bash -n experiments/labs/ipv6-ula-foundation/run.sh
  - experiments/labs/ipv6-ula-foundation/run.sh
  - ip netns list | grep -E 'pocket-v6-(a|b)' returns no match after cleanup
transcript: experiments/transcripts/ipv6-ula-foundation-20260620T000000Z.txt
technical_review:
  required: true
  status: deferred
```

This lab validates the IPv6 and ULA foundation chapter.

It creates two temporary namespaces, connects them with one IPv6 ULA link,
adds a service loopback, observes IPv6 route lookup and NDP, then rolls
everything back.

Run from the repository root on Linux:

```sh
bash experiments/labs/ipv6-ula-foundation/run.sh
```

Run from macOS with OrbStack:

```sh
orb bash experiments/labs/ipv6-ula-foundation/run.sh
```
