# Reader Knowledge Ledger

This ledger records what the book has already taught. Beginner reviews should assume the reader knows only the concepts listed up to the chapter immediately before the chapter under review.

Use this file to keep chapter drafts honest:

- Add new terms after the chapter that introduces them.
- Keep definitions plain and concrete.
- List important ideas that have not been introduced yet so later drafts do not accidentally assume them.

## Before Part 1

Reader can be assumed to know:

- how to run shell commands when shown exactly what to type,
- that computers can send packets to other computers,
- that an IP address is related to networking, but not how routing works.

Reader has not yet been taught:

- Linux network namespaces,
- subnets or prefix lengths,
- routing tables,
- next hops,
- packet forwarding,
- WireGuard,
- BIRD,
- BGP,
- DN42 registry objects,
- DNS delegation.

## After Part 1, Chapter 1: Linux as a Router

Introduced by `docs/part-01-first-principles/01-linux-networking.md`.

Reader has seen:

- network namespace: a separate networking world inside Linux,
- network stack: the interfaces, addresses, routes, and packet rules inside that world,
- interface: a place where packets enter or leave a network stack,
- veth pair: a virtual Ethernet cable with two ends,
- IP address: a label assigned to an interface,
- prefix: a group of addresses written as a starting address plus a length,
- local link: a network segment directly reachable through one interface,
- route: an instruction that tells Linux where to send packets for a destination,
- next hop: the next router a packet should be sent to,
- route lookup: asking Linux which route it would use for a packet,
- forwarding: receiving a packet not addressed to this machine and sending it onward,
- TTL: a hop counter that decreases when a packet crosses a router,
- `ip -n NAME ...`: an `ip` command aimed at a specific namespace,
- `ip netns exec NAME ...`: a way to run any command inside a namespace.

Reader has only been lightly introduced to:

- packet path reasoning across one router.

Reader has not yet been taught:

- route selection with multiple matching routes,
- policy routing and multiple route tables,
- WireGuard cryptokey routing,
- BIRD configuration,
- BGP sessions,
- ASNs,
- DN42 registry objects,
- DNS forwarding or delegation.
