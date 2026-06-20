# Pocket Internet Beginner Review

Reviewed on: 2026-06-20

Issue: #59

Scope:

- `docs/start-here.md`
- `docs/pocket-internet.md`
- `docs/linux-networking-objects.md`
- `docs/safety.md`
- `docs/part-01-first-principles/01-linux-networking.md`
- `docs/part-01-first-principles/02-addressing-and-subnets.md`
- `docs/part-01-first-principles/03-pocket-internet-static-routing.md`
- `docs/part-01-first-principles/04-routing-tables.md`
- `docs/part-01-first-principles/05-bird-as-route-manager.md`
- `docs/part-01-first-principles/06-bgp-before-dn42.md`
- `docs/part-01-first-principles/07-operate-a-service.md`
- `docs/part-01-first-principles/08-links-tunnels-underlays-overlays.md`
- `docs/part-01-first-principles/09-wireguard-as-a-link.md`
- `docs/part-01-first-principles/10-bgp-over-wireguard.md`
- `docs/part-01-first-principles/11-local-link-observation.md`
- `docs/part-01-first-principles/12-ipv6-ula-foundation.md`
- `docs/part-01-first-principles/13-packet-filtering-foundation.md`
- `docs/part-01-first-principles/14-dns-and-naming-foundation.md`
- `docs/part-01-first-principles/15-observability-and-troubleshooting.md`

Review stance: first-time networking reader who is willing to type commands carefully, but does not already understand Linux namespaces, local-link delivery, routing-daemon concepts, DNS resolver behavior, packet filtering, or BGP operations.

## Verdict

Part 1 is worth reading. It has a real teaching shape, not just a sequence of commands. The strongest idea is still the right one: build a small Internet from concrete Linux objects, feel the pain of manual routing, then let routing protocols reduce that pain.

The section is not yet beginner-stable as a complete learning path. The main risk is not factual weakness. The risk is that a careful beginner can follow each command and still carry too much unresolved confusion from chapter to chapter. The biggest gaps are sequencing, lab continuity, and config density.

This review should lead to follow-up issues before the technical review becomes the main focus.

## P1 Findings

### 1. Local-link observation arrives too late

Impact: reader-blocking.

The book uses connected route, local link, next hop, veth, route lookup, and packet delivery for many chapters before the reader sees the mechanism underneath local delivery.

Examples:

- `01-linux-networking.md` introduces route lookup, forwarding, and return path before any packet observation lab. The lab setup at lines 151-163 handles root and environment well, but the "did the packet leave?" mental model is still mostly inferred.
- `02-addressing-and-subnets.md` lines 77-148 explains address versus prefix, connected routes, and a LAN analogy. This is useful, but it asks the reader to accept "reachable directly through `wlan0`" before seeing ARP, neighbor entries, or captured packets.
- `11-local-link-observation.md` lines 30-70 finally slows down and explains ARP, neighbor tables, packet capture, and the difference between route lookup and local-link delivery.

Why this matters: the `/30` and "on-link" confusion is predictable. A beginner may understand that Linux chose an interface while still not understanding what has to happen on that link. The current order leaves that mystery open until chapter 11.

Recommended structural revision:

- Split `11-local-link-observation.md`.
- Move a short "local link and packet movement" primer immediately after `01-linux-networking.md` or `02-addressing-and-subnets.md`.
- Keep any deeper packet-capture/NDP material later if needed.

Quick edit available before the structural move:

- Add earlier cross-links from the first two chapters to the local-link observation chapter, explicitly saying, "This will feel abstract until the packet observation chapter."

### 2. Lab continuity and rebuild burden are still too high

Impact: reader-blocking over multiple sessions.

The manual-first choice is correct, but Part 1 now has long dependent labs. A reader who does the book over several days will repeatedly rebuild large amounts of topology state.

Examples:

- `07-operate-a-service.md` lines 117-143 starts as a dependent extension of the BGP Pocket Internet and asks the reader to rebuild the BGP lab if the checkpoint is missing.
- `10-bgp-over-wireguard.md` lines 155-163 directly acknowledges that rebuilding from scratch is not ideal for reader ergonomics.
- `03-pocket-internet-static-routing.md` and `06-bgp-before-dn42.md` are both more than 4,300 words and require substantial command state before the payoff.

Why this matters: manual setup teaches the objects, but repeated manual setup can become noise. The reader should burn the model into memory, not spend attention retyping boilerplate before the actual new concept.

Recommended structural revision:

- Keep first builds manual.
- Add named checkpoint restore commands for later dependent chapters.
- Make each dependent chapter start with two paths:
  - learning path: rebuild manually if this is your first time,
  - resume path: restore the named checkpoint, verify it, then continue.

Quick edit available:

- Standardize a "Checkpoint Required" block in dependent chapters.
- Name exact preconditions in the same format every time.

### 3. BIRD and BGP config density risks paste-without-understanding

Impact: reader-blocking for the first control-plane chapters.

The BIRD chapters are valuable, but the first full BGP configuration is a lot to hold at once.

Examples:

- `06-bgp-before-dn42.md` lines 323-418 introduces one full BIRD config with router ID, direct protocol, kernel protocol, import filter, export filter, and two BGP sessions.
- `06-bgp-before-dn42.md` lines 420-429 starts a helpful boundary table, but the reader has already crossed the densest block.
- `10-bgp-over-wireguard.md` contains another large BGP-over-WireGuard build after the reader has already rebuilt the topology.

Why this matters: this is the moment where the book changes from Linux route tables to a routing daemon. If the reader pastes config without understanding the shape, BGP becomes a magic config blob instead of route-table automation.

Recommended structural revision:

- Add a BIRD config anatomy section before the first full config.
- Teach the shape in smaller stages:
  - BIRD identity,
  - direct route learning,
  - BIRD-to-kernel export,
  - one BGP neighbor,
  - repeated neighbors and filters.
- Use MkDocs code annotations and titles consistently, but avoid making annotations carry the entire explanation.

Quick edit available:

- Add a short "Read the config in this order" table immediately before the first heredoc.

### 4. Lab requirements are useful but inconsistent

Impact: reader-blocking when a reader hits permissions or missing tools.

Later chapters have clearer requirements blocks than early chapters.

Examples:

- `01-linux-networking.md` lines 151-163 explains root and OrbStack in prose.
- `10-bgp-over-wireguard.md` lines 134-154 has a stronger `Lab Requirements` block with commands and expected observations.
- DNS, filtering, and troubleshooting chapters follow a more explicit preflight style.

Why this matters: beginners do not always know whether a failure is their mistake, a missing package, a non-root shell, or a host-vs-lab environment mismatch.

Recommended quick edit:

- Add a standard `Lab Requirements` block to every lab chapter.
- Include:
  - environment,
  - root requirement,
  - required commands,
  - expected observations,
  - validation script,
  - transcript path.

This is a quick edit category, not a deep structural rewrite.

## P2 Findings

### 5. Long chapters need more "you are here" state snapshots

Impact: medium-high cognitive load.

The static routing chapter shows the pattern well:

- `03-pocket-internet-static-routing.md` lines 516-542 explains route-writing pain in a human way.
- `03-pocket-internet-static-routing.md` lines 600-617 gives a state snapshot after selected routes exist.

That pattern should be used more aggressively in the BIRD/BGP and WireGuard+BGP chapters.

Recommended revision:

- Add state snapshots before and after major transitions:
  - before BIRD starts,
  - after BIRD learns loopbacks,
  - after BGP sessions establish,
  - after routes export to Linux,
  - after WireGuard replaces one link,
  - after BGP runs over WireGuard.

### 6. Route-selection repetition needs a clearer transition

Impact: medium conceptual friction.

The book intentionally returns to route selection several times. That is good, but the distinction between "prefix match practice" and "router job practice" should be more explicit.

Examples:

- `02-addressing-and-subnets.md` introduces prefix specificity and route matching.
- `04-routing-tables.md` revisits route selection in the context of a router choosing among possible installed routes.

Recommended quick edit:

- Add a transition note in the Part 1 overview:
  - chapter 2 teaches how Linux chooses a matching route,
  - chapter 4 teaches what that means when a router has multiple possible paths.

### 7. Tone is strongest when the book admits the work is annoying

Impact: medium motivation issue.

The best tone appears when the book acknowledges the human experience of the lab.

Example:

- `03-pocket-internet-static-routing.md` lines 540-542 says the route-writing annoyance is the point and connects that feeling to why BGP exists.

Recommended revision:

- Preserve this style.
- Add restrained human framing around config-heavy sections:
  - "This is a lot of config because the router has several boundaries."
  - "The goal is not to memorize the syntax. The goal is to identify which boundary a line belongs to."

Avoid performative jokes. Use the frustration of the lab as a teaching signal.

### 8. Tooltip density may become visually noisy

Impact: medium reading-flow issue.

The glossary and tooltip system are useful. In dense paragraphs, too many underlined terms can compete with the sentence.

Recommended review action:

- During the next editing pass, scan for paragraphs with several glossary terms close together.
- Consider using tooltips most heavily for new or recently introduced terms, while relying on normal links or glossary pages for older terms.

This should be treated as a design/content polish issue, not a reason to remove the glossary mechanism.

### 9. The observability runbook is good, but it may work better as a field guide

Impact: medium sequencing issue.

`15-observability-and-troubleshooting.md` lines 39-80 correctly reframes troubleshooting as one question at a time. That is valuable and should stay.

The question is placement. A beginner may experience it as another dense chapter after many labs. It may work better as:

- a short capstone chapter,
- a reusable field guide page,
- and a set of backlinks from earlier labs when each diagnostic command first appears.

Recommended structural revision:

- Keep the runbook.
- Add more "return to the runbook" references inside earlier chapters.
- Consider labeling it as a field guide rather than another linear lab.

## P3 Findings

### 10. Start Here should set effort expectations

Impact: low, but useful.

Part 1 is now a real course of study. The front matter should say that some labs are long and that readers should expect to work in sessions.

Recommended quick edit:

- Add a short expectation note:
  - do one major lab per sitting,
  - use validation scripts for repeat runs,
  - keep manual setup for first exposure,
  - expect confusion around `/30`, next hops, and return paths until the examples repeat.

### 11. Diagrams are now more consistent, but BGP sections still need progress visuals

Impact: low-medium.

The Mermaid-first visual language from the diagram audit is an improvement. The remaining beginner need is not only diagram consistency, but diagram timing.

Recommended revision:

- Add diagrams at state changes, not only at chapter openings.
- Keep command-adjacent topology inventories as text when they show exact names the reader must type.

## Strengths to Preserve

- Manual-first labs. The reader should build the network objects by hand at least once.
- "What this proves / what this does not prove" callouts.
- Rollback and cleanup discipline.
- The Pocket Internet framing: build a small Internet first, then use DN42 as the bridge to a living network.
- The route-maintenance pain before BGP. That frustration is educational.
- Separating Linux route tables, BIRD route state, BGP sessions, WireGuard link state, service listeners, DNS, filters, and packet observation.
- Human explanations that connect the lab feeling to the concept being taught.

## Suggested Remediation Order

1. Standardize `Lab Requirements` and checkpoint blocks across Part 1.
2. Move or split local-link observation so packet movement appears earlier.
3. Define the checkpoint/resume pattern for dependent labs.
4. Add BIRD/BGP config anatomy and more state snapshots.
5. Add small transition notes for repeated route-selection concepts.
6. Tune tooltip density and tone during the same pass.
7. Re-review Part 1 as a beginner path.
8. Then run the technical review.

## Review Boundary

This issue did not change lesson content. It intentionally records beginner-readiness findings so the next work can be sequenced deliberately.
