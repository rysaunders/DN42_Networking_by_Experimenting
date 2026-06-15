# Start Here

This book assumes curiosity and basic command-line comfort, not professional network engineering experience.

## Reader Path

1. Learn what Linux does with interfaces, addresses, routes, and forwarding.
2. Build Toy DN42: a small local Internet made of Linux namespaces and veth links.
3. Add loopback service addresses and static routes.
4. Run BIRD and BGP locally before touching public DN42 peers.
5. Replace one local link with WireGuard so tunnels become ordinary links in the reader's mental model.
6. Register DN42 resources only after the registry workflow is understood.
7. Add one public peer, one routing daemon, split DNS, and one reachable service.

Toy DN42 is the spine of the book. Each early lab should add one new behavior to that local topology unless it is teaching a primitive the topology depends on.

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
