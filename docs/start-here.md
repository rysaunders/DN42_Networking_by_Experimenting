# Start Here

This book assumes curiosity and basic command-line comfort, not professional network engineering experience.

## Reader Path

1. Learn what Linux does with interfaces, addresses, routes, and forwarding.
2. Build a small local routed lab.
3. Add WireGuard as an overlay link.
4. Run BGP locally before touching public DN42 peers.
5. Register DN42 resources only after the registry workflow is understood.
6. Add one public peer, one routing daemon, split DNS, and one reachable service.

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
