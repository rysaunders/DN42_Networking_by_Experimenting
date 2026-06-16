# Building a Small Internet

Networking by Experimenting with DN42 is a hands-on book/site for learning networking by building, breaking, observing, and explaining a small Internet.

This project is intentionally not a copy-and-paste setup guide. Each chapter should connect a lab observation to a networking concept, then explain how the same idea appears in DN42 and on the public Internet.

The guiding question is:

> How does an Internet emerge from a collection of computers exchanging routes?

## Current Scope

The first release target is `v0.1`: Pocket Internet foundation, route-selection labs, BIRD/BGP inside the lab, one WireGuard-replaced lab link, and a safe DN42 border design.

The first version of the site focuses on:

- Linux networking fundamentals.
- Addressing and route lookup.
- Pocket Internet: a local laboratory built from namespaces, veth links, loopbacks, BIRD, and controlled failures.
- WireGuard as a replacement for one local link.
- BGP concepts inside the local topology before public DN42 configuration.
- The Pocket Internet to DN42 interconnect as the bridge from lab routing to a living network.
- DN42 registry objects and first-peer chapters remain later-phase drafts until the lab foundation and border model are clear.

## Project Rules

- Prefer tested local labs before public DN42 commands.
- Teach through Pocket Internet before asking the reader to touch real DN42 peers.
- Treat DN42 as the bridge to a living network, not as isolated setup instructions.
- Mark current DN42 practice as source-dependent.
- Keep safety checks and rollback steps visible.
- Preserve source metadata and research notes.
- Use GitHub Issues for tracked work.
