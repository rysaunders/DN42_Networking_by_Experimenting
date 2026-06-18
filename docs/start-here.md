# Start Here

This book assumes curiosity and basic command-line comfort, not professional network engineering experience.

The first arc is Pocket Internet: a local lab where Linux namespaces become small routers, veth pairs become links, loopbacks become service addresses, and routing tables decide where packets go. DN42 comes later, after those pieces are familiar enough to use safely on a real shared network.

If the early Linux terms start to blur together, keep [Linux Networking Objects](linux-networking-objects.md) open as the visual map. It shows how namespaces, interfaces, addresses, routes, loopback, and forwarding fit together before the labs start combining them.

## Reader Path

1. Learn what Linux does with interfaces, addresses, routes, and forwarding.
2. Build Pocket Internet: a small local Internet made of Linux namespaces and veth links.
3. Add loopback service addresses and static routes.
4. Run BIRD and BGP locally before touching public DN42 peers.
5. Replace one local link with WireGuard so tunnels become ordinary links in the reader's mental model.
6. Build a clear border between Pocket Internet and DN42.
7. Register DN42 resources only after prefixes, route advertisements, and return paths are understood.
8. Add one public peer, one routing daemon, split DNS, and one reachable service.

Pocket Internet is the lab, not the destination. DN42 is the bridge from that lab into a living routing ecosystem.

The guiding question for every chapter is:

> How does an Internet emerge from a collection of computers exchanging routes?

Each early lab should add one new behavior to Pocket Internet unless it is teaching a primitive the topology depends on.

## How to Read Labs

Each lab should answer four questions:

- What concept is being tested?
- What should change on the system?
- What command proves it changed?
- What command rolls it back?

If a lab does not answer those questions yet, treat it as a draft.

## Source Labels

Principle
: A stable networking idea.

Linux behavior
: Behavior specific to Linux tools or kernel versions.

DN42 current practice
: Community practice that must be refreshed before release.

Lab simplification
: A deliberate simplification used to teach one idea at a time.
