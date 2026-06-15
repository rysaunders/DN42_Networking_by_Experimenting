# Building a Small Internet

Networking by Experimenting with DN42 is a hands-on book/site for learning networking by building, breaking, observing, and explaining a small Internet.

This project is intentionally not a copy-and-paste setup guide. Each chapter should connect a lab observation to a networking concept, then explain how the same idea appears in DN42 and on the public Internet.

## Current Scope

The first release target is `v0.1`: zero to one safe DN42 peer, split DNS, and first service access.

The first version of the site focuses on:

- Linux networking fundamentals.
- Addressing and route lookup.
- WireGuard as an overlay link.
- BGP concepts before public DN42 configuration.
- DN42 registry objects, first peer setup, BIRD, kernel routes, DNS, and first service access.

## Project Rules

- Prefer tested local labs before public DN42 commands.
- Mark current DN42 practice as source-dependent.
- Keep safety checks and rollback steps visible.
- Preserve source metadata and research notes.
- Use GitHub Issues for tracked work.
