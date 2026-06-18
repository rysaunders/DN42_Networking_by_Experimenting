# Pocket Internet to DN42 Border

Pocket Internet is the lab. DN42 is the living network beyond the lab.

The border is where local lab reasoning meets shared routing practice. It should teach containment before connection.

This page is not a promise that the book will publish Pocket Internet routes into DN42 by default. The safer default is to keep Pocket Internet local, then use the border model to make real DN42 setup feel intuitive instead of magical.

!!! note "Default export stance"

    Pocket Internet prefixes and AS labels are lab-only unless a later DN42 chapter replaces them with authorized resources. The default border design sends no Pocket Internet routes into DN42. Any exception must name the authorized prefix, show the exact export filter, and include rollback.

## Reader Starting Point

This is a later design page. It is here so the project has a clear destination, not because a new reader should implement it immediately.

Before implementing this design, the reader should already understand:

- route lookup,
- forwarding,
- return path,
- WireGuard as a link,
- BIRD and BGP at a basic level,
- import and export filters,
- authorized prefixes.

For now, read this page as a map of where Pocket Internet is going.

## Border Terms

- Border router: the router where Pocket Internet meets DN42.
- Outbound reachability: Pocket Internet sends traffic toward DN42.
- Inbound reachability: DN42 sends traffic toward a selected service behind the border.
- Return path: the route a reply packet uses to get back to the original sender.
- Route advertisement: telling another router that you can carry traffic for a prefix.
- Import filter: a rule for which routes you accept from a neighbor.
- Export filter: a rule for which routes you announce to a neighbor.
- Route leak: accidentally announcing or accepting routes that should not cross the border.
- Authorized prefix: an address block you are allowed to announce.
- Lab-only prefix: an address block used only inside the local lab.

## Goal

The first goal is border literacy:

```text
Pocket Internet side -> border router -> DN42 side
```

The reader should be able to explain what is allowed to cross that boundary, what is blocked, and how to prove both.

Outbound reachability is a later design question:

```text
Pocket Internet service or host -> Pocket Internet border -> DN42 peer -> DN42 service
```

Inbound reachability is a later goal and must be authorized:

```text
DN42 node -> DN42 peer -> Pocket Internet border -> selected Pocket Internet service
```

The book should not imply that lab addresses can be advertised to DN42. Only authorized DN42 resources should ever be exported toward a DN42 peer.

## Border Model

Use a dedicated border namespace or router.

```mermaid
flowchart LR
  PI["Pocket Internet routers and services"]
  BORDER["Pocket Internet border router"]
  WG["WireGuard link"]
  DN42["DN42 peer and routes"]

  PI --> BORDER
  BORDER --> WG
  WG --> DN42
```

The border has two jobs:

- speak the Pocket Internet side of the lab,
- speak the DN42 side of the real peer.

Keeping those roles visible makes route leaks easier to reason about.

## Design Principles

- Pocket Internet to DN42 is a border, not a shortcut.
- Pocket Internet remains the laboratory; it is not the thing being published by default.
- Do not install a default route into DN42 unless a chapter explicitly proves why it is safe.
- Do not advertise routes into DN42 unless the prefix is authorized and filters are explicit.
- Start with containment: no default route into DN42 and no Pocket Internet route export.
- Treat outbound reachability as a deliberate design, not a default assumption.
- Treat return path as a first-class concept.
- Prefer explicit import and export filters over permissive examples.
- Include rollback and "what could leak?" checks in every border chapter.

## Return Path

A packet path is useful only if the reply can get back.

Outbound traffic from Pocket Internet to DN42 has two routing questions:

- Does Pocket Internet know how to send the packet to the border?
- Does DN42 know how to send the reply back to the source?

If the source address is private lab-only space, DN42 will not know how to return the packet. A later chapter must either use an authorized DN42 prefix, translate at the border, or choose a test where return reachability is intentionally out of scope.

That is why outbound reachability is not the default first action. Without a valid return path, "send packets toward DN42" can become confusing rather than instructive.

## Route Advertisement

Export policy is the line between a lab and a route leak.

Before any route is advertised toward DN42, the chapter must show:

- which prefix is being advertised,
- why that prefix is authorized,
- which filter permits it,
- which filter rejects everything else,
- how to verify what BIRD will export,
- how to roll the change back.

For the default learning path, Pocket Internet routes are not exported toward DN42. The real DN42 chapters should use authorized DN42 resources and normal peer expectations instead of asking DN42 to accept arbitrary lab topology.

## What This Enables

The advanced payoff is understanding the boundary well enough to operate safely:

- The reader can configure a real DN42 node without treating BGP, filters, and kernel routes as recipes.
- Pocket Internet can remain a private testbed for concepts before real DN42 changes.
- Services can cross the boundary only after return path, authorization, filtering, and rollback are explicit.
- The reader can compare lab routing behavior with real routing behavior instead of treating DN42 as a separate recipe.
