# Reader Knowledge Ledger

This ledger records what the book has already taught. Beginner reviews should assume the reader knows only the concepts listed up to the chapter immediately before the chapter under review.

Use this file to keep chapter drafts honest:

- Add new terms after the chapter that introduces them.
- Keep definitions plain and concrete.
- List important ideas that have not been introduced yet so later drafts do not accidentally assume them.

Recurring checkpoint labels such as "You can now explain," "Still okay if fuzzy," and "Next we need" are reader scaffolding, not technical concepts. They should summarize only what the reader has already seen or name the immediate learning gap without adding new required vocabulary.

The visual glossary at `docs/linux-networking-objects.md` is a reference map. It may preview terms before a lab teaches them, but beginner reviews should not assume the reader has mastered a term until the chapter ledger below says the reader has seen it in context.

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
- connected route: a route Linux creates automatically when an interface has an address and prefix,
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

## After Part 1, Chapter 2: Addresses, Prefixes, and Longest Match

Introduced by `docs/part-01-first-principles/02-addressing-and-subnets.md`.

Reader has seen:

- prefix length: the number after `/`,
- host route: a route for exactly one IP address,
- default route: the fallback route when nothing more specific matches,
- longest-prefix match: the most specific matching route wins,
- route specificity: `/32` is more specific than `/24`, which is more specific than `/16`,
- overlapping routes: several routes can match the same destination at the same time,
- route fallback: removing a more-specific route can reveal the next-best broader route,
- source address note: route lookup can show the source address Linux would prefer for that route.

Reader has only been lightly introduced to:

- source address selection.

Reader has not yet been taught:

- policy routing and multiple route tables,
- WireGuard cryptokey routing,
- BIRD configuration,
- BGP sessions,
- ASNs,
- DN42 registry objects,
- DNS forwarding or delegation.

## After Part 1, Pocket Internet with Static Routes

Introduced by `docs/part-01-first-principles/03-pocket-internet-static-routing.md`.

Reader has seen:

- autonomous system: for now, one independently controlled network boundary,
- AS-shaped namespace: a namespace used as a local autonomous-system model in the lab,
- loopback: the `lo` interface inside a namespace,
- service loopback: a stable address on `lo` that represents a service or prefix an AS could advertise later,
- point-to-point link: a link with one device on each end,
- static route: a route written by hand,
- transit namespace: a namespace that forwards packets between other namespaces,
- static route repair: changing route tables by hand after a topology change,
- alternate physical path: a path that exists as links but is unused until routing points at it.

Reader has only been lightly introduced to:

- convergence as the process of routing recovering after a change.

Reader has not yet been taught:

- dynamic routing,
- BIRD configuration,
- BGP sessions,
- AS_PATH,
- local preference,
- route import and export policy,
- WireGuard cryptokey routing,
- DN42 registry objects,
- DNS forwarding or delegation.

## After Part 1, Pocket Internet Route Selection

Introduced by `docs/part-01-first-principles/04-routing-tables.md`.

Reader has seen:

- edge router: a router at the edge of a network, where traffic leaves toward another network,
- exit: the interface and next hop a route points toward,
- fallback route: a broader route used when no more-specific route matches,
- route lookup inside a Pocket Internet edge-router context,
- connected route as the reason a next-hop address is accepted,
- route fallback from `/32` to `/24` to `/16`.

Reader has only been lightly introduced to:

- route selection as a behavior that will continue after BGP installs routes automatically.

Reader has not yet been taught:

- dynamic routing,
- BIRD configuration,
- BGP sessions,
- AS_PATH,
- local preference,
- route import and export policy,
- WireGuard cryptokey routing,
- DN42 registry objects,
- DNS forwarding or delegation.

## After Part 1, BGP Before DN42

Introduced by `docs/part-01-first-principles/06-bgp-before-dn42.md`.

Reader has seen:

- routing daemon: a background program that manages routes,
- BIRD: the routing daemon used in the Pocket Internet lab,
- BGP: a protocol routers use to exchange reachability,
- BGP session: one BGP conversation between two routers,
- neighbor: the router on the other side of a BGP session,
- local AS: the autonomous system number a router uses for itself,
- peer AS: the autonomous system number expected from the neighbor,
- route advertisement: telling a neighbor that a prefix is reachable,
- import filter: a rule for deciding which received routes to accept,
- export filter: a rule for deciding which routes to announce,
- kernel protocol: the BIRD component that installs selected routes into Linux,
- convergence: the network settling on new routes after a change,
- BIRD route state and Linux route state as related but separate views,
- route withdrawal after BGP sessions lose reachability.

Reader has only been lightly introduced to:

- AS path as route metadata,
- BGP path choice when more than one route exists.

Reader has not yet been taught:

- local preference,
- BGP communities,
- WireGuard cryptokey routing,
- DN42 registry objects,
- DNS forwarding or delegation.

## After Part 1, Operate a Service Inside Pocket Internet

Introduced by `docs/part-01-first-principles/07-operate-a-service.md`.

Reader has seen:

- service: a program that listens for network connections and responds,
- listener: the address and port where a service waits for connections,
- bind address: the local address a service attaches to,
- port: a number identifying a service on an address,
- HTTP: a simple request/response protocol used by web servers and clients,
- application traffic: traffic for a real program instead of a routing probe,
- listener binding as separate from route reachability,
- `ss` as a way to inspect listening sockets,
- service logs as evidence of the source address reaching the application.

Reader has only been lightly introduced to:

- service troubleshooting as a layered routing, listener, source, and return-path problem.

Reader has not yet been taught:

- host-to-lab access,
- firewall rules around services,
- persistent service supervision,
- DNS forwarding or delegation,
- WireGuard cryptokey routing,
- DN42 registry objects.

## After Part 1, Links, Tunnels, Underlays, and Overlays

Introduced by `docs/part-01-first-principles/08-links-tunnels-underlays-overlays.md`.

Reader has seen:

- VPN: a tool that creates a private-looking network path across another network,
- tunnel: a logical link carried inside another network path,
- underlay: the network that carries tunnel packets,
- overlay: the logical network created on top of an underlay,
- inner packet: the packet the lab network thinks it is sending,
- outer packet: the packet that carries the inner packet across the underlay,
- veth as the local lab stand-in for a public carrier network,
- `10.42.23.2` as an overlay neighbor and `192.0.2.2` as an underlay endpoint in the WireGuard lab shape,
- BGP as a protocol that can run over any reachable link, including a tunnel.

Reader has only been lightly introduced to:

- WireGuard as the tool that will create the tunnel in the next lab.

Reader has not yet been taught:

- WireGuard key setup,
- WireGuard endpoint configuration,
- WireGuard `AllowedIPs`,
- WireGuard handshakes,
- MTU sizing,
- NAT traversal and persistent keepalive,
- `wg-quick`,
- real DN42 peer expectations,
- DN42 registry objects.

## After Part 1, Build and Verify a WireGuard Link

Introduced by `docs/part-01-first-principles/09-wireguard-as-a-link.md`.

Reader has seen:

- WireGuard: a VPN protocol that creates encrypted tunnel interfaces,
- private key: a secret WireGuard key that stays local,
- public key: the key given to a peer,
- endpoint: the underlay IP and UDP port where a peer receives WireGuard packets,
- handshake: evidence that WireGuard peers exchanged setup traffic,
- AllowedIPs: WireGuard's peer-selection and packet-allow list,
- `AllowedIPs` limited to the overlay neighbor address in a raw `wg set` lab,
- underlay and overlay route lookups as separate checks,
- WireGuard counters as evidence that overlay traffic crossed the tunnel.

Reader has only been lightly introduced to:

- WireGuard as a link that BGP can use later.

Reader has not yet been taught:

- BGP running over WireGuard,
- broadening `AllowedIPs` for service-loopback traffic,
- MTU sizing,
- NAT traversal and persistent keepalive,
- `wg-quick`,
- real DN42 peer expectations,
- DN42 registry objects.

## After Part 1, Run BGP Over WireGuard

Introduced by `docs/part-01-first-principles/10-bgp-over-wireguard.md`.

Reader has seen:

- WireGuard replacing the AS2-AS3 veth link in the four-AS Pocket Internet,
- BGP running over WireGuard overlay addresses,
- in this raw `wg set` lab, AllowedIPs does not create the BGP-learned routes; later tools may also use AllowedIPs to install routes,
- `AllowedIPs` broadened to include service-loopback destinations carried through the tunnel,
- BGP import/export policy as separate from WireGuard peer-selection rules,
- route lookups and transfer counters as evidence that service-loopback traffic crossed the tunnel.

Reader has only been lightly introduced to:

- host-to-lab access as a later outside-path question.

Reader has not yet been taught:

- MTU sizing,
- NAT traversal and persistent keepalive,
- `wg-quick`,
- real DN42 peer expectations,
- DN42 registry objects.
