# Packet Filtering Foundation

## Lab Metadata

```yaml
experiment_id: experiments/labs/packet-filtering-foundation
status: validated
safety_level: local-lab
chapter: docs/part-01-first-principles/13-packet-filtering-foundation.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - nftables
  - python3
  - curl
  - ping
setup_assumptions:
  - temporary namespace names pocket-filter-client and pocket-filter-server are available
  - nft, python3, curl, and ping are installed in the Linux lab environment
cleanup_guarantees:
  - stops the lab HTTP listener
  - deletes both packet-filter lab namespaces
  - removes veth, route, nftables, and process state with the namespaces
  - removes temporary service files
expected_state:
  - two namespaces connected by one IPv4 /30 veth link
  - HTTP listener bound to 10.88.0.2:8080 inside pocket-filter-server
  - nftables input chain inside pocket-filter-server
  - TCP/8080 from 10.88.0.1 is accepted
  - ICMP echo requests are dropped by a counter rule
  - no host firewall or persistent nftables rules are changed
validation_commands:
  - bash -n experiments/labs/packet-filtering-foundation/run.sh
  - experiments/labs/packet-filtering-foundation/run.sh
  - ip netns list | grep -E 'pocket-filter-(client|server)' returns no match after cleanup
transcript: experiments/transcripts/packet-filtering-foundation-20260620T000000Z.txt
technical_review:
  required: true
  status: deferred
```

This lab validates the packet-filtering foundation chapter.

It creates a client namespace, a server namespace, a small HTTP service, and a
namespace-local nftables filter. It proves that route lookup can be correct
while policy still allows one kind of traffic and drops another.

Run from the repository root on Linux:

```sh
bash experiments/labs/packet-filtering-foundation/run.sh
```

Run from macOS with OrbStack:

```sh
orb bash experiments/labs/packet-filtering-foundation/run.sh
```
