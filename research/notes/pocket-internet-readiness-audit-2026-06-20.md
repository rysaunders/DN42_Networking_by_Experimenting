# Pocket Internet Internet-Readiness Audit

Reviewed on: 2026-06-20

Scope:

- `docs/part-01-first-principles/*.md`
- `docs/pocket-internet.md`
- `docs/pocket-internet-dn42-interconnect.md`
- `docs/safety.md`
- `docs/reader-knowledge.md`

Standard used: `docs/authoring-templates/internet-readiness-standard.md`

## Verdict

The Pocket Internet foundation is strong enough to re-review as a coherent first arc after convention metadata is retrofitted. It teaches route lookup, return path, BIRD/Linux separation, BGP route exchange, service listener behavior, and WireGuard-as-link with unusually clear lab boundaries.

The main risk is not that the current material is wrong. The risk is false completeness: a reader could finish Part 1 comfortable with Linux routing labs but still lack enough Internet-adjacent knowledge to safely approach DN42 or public routing. The book now names many of those gaps, but several need planned chapters before real DN42 work becomes implementation-ready.

## What Works

- The labs repeatedly separate route lookup, packet delivery, control-plane state, kernel route state, tunnel state, and service listener state.
- Evidence callouts reduce overclaiming. `ping`, `wg show`, `birdc show route`, and `curl` are usually framed as narrow evidence rather than universal proof.
- Lab-only ASNs, prefixes, and kernel export shortcuts are called out.
- Safety and border pages clearly prohibit default-route accidents and unauthorized route export.
- The route-maintenance pain is educationally useful. Static routing feels tedious before BGP appears, which supports the learning arc.
- Diagrams now reduce topology and state-tracking load in the most command-heavy sections.

## High-Priority Gaps

### IPv6 and ULA

Current state: IPv4-only simplification is clearly labeled, and safety notes say IPv6/ULA must be taught before production-shaped DN42 chapters rely on them.

Gap: there is not yet a chapter that actually teaches IPv6 notation, ULA, NDP, route lookup, BIRD shape, and DN42 expectations.

Decision: later chapter before real DN42 peering implementation, not a retrofit into every existing lab.

Follow-up: #53.

### Local-Link Discovery and Packet Observation

Current state: local links and connected routes are explained, and packet counters are used as supporting evidence.

Gap: the reader has not seen ARP/NDP, neighbor tables, or packet capture as the mechanism and evidence behind "same link" delivery. This leaves "on-link" behavior partly abstract.

Decision: add a small foundation lab before or near the first DN42-facing work. It does not need to derail the current Part 1 flow, but it should exist before the reader troubleshoots real tunnels, peers, or services.

Follow-up: #54.

### Firewall and Filtering

Current state: firewall policy is named as a possible failure mode and a DN42 safety concern.

Gap: the reader has not practiced packet filtering. A real DN42 node without firewall intuition is unsafe, especially once services or forwarding are exposed.

Decision: add a local firewall/filtering foundation lab before real service exposure or DN42 interconnect commands.

Follow-up: #55.

### DNS and Naming

Current state: DNS is repeatedly named as future work, and service reachability uses raw addresses.

Gap: the reader has not learned naming, resolver behavior, split DNS, or the difference between routing reachability and name resolution.

Decision: add a Pocket Internet DNS/naming foundation before `.dn42` split DNS.

Follow-up: #56.

### Observability and Operations

Current state: labs use route lookup, counters, BIRD state, WireGuard state, `ss`, logs, and cleanup checks.

Gap: those checks are chapter-local. The reader does not yet have a reusable operational troubleshooting map: logs, packet captures, routing daemon state, service state, rollback proof, and what to inspect first.

Decision: add an observability/troubleshooting foundation or runbook before real DN42 operations. Some pieces can be integrated into the convention retrofit from #52, but a standalone operator-focused chapter is still useful.

Follow-up: #57.

## Medium-Priority Gaps

- Source address selection is introduced but not deeply practiced. It becomes important at the DN42 border and with services.
- NAT is named but not taught. It should be taught only when the border design needs translation or when WireGuard underlay examples require NAT traversal.
- MTU is named but not measured. It belongs with the real-underlay/WireGuard bridge, before real peer instructions.
- TLS and service identity are not taught. This belongs later, after DNS and basic service reachability.
- Abuse handling and operational responsibility are named only indirectly. This belongs in later real-service and public-network chapters.
- BGP policy beyond basic import/export filters is only lightly introduced. Local preference, communities, prefix limits, and ROA/RPKI-like validation belong after first-peer basics.

## Reader Knowledge Ledger Check

The ledger matches the current Part 1 chapter sequence through `10-bgp-over-wireguard.md`.

Quick fix applied during this audit: added a ledger entry for `docs/pocket-internet-dn42-interconnect.md`, because future DN42 chapters should be allowed to assume the reader has seen border, route leak, authorized prefix, return path, export dry-run, and public Internet sanity-check concepts.

Remaining ledger work: #52 should retrofit the new metadata/review conventions and may also normalize status/review notes across existing chapters and labs.

## Quick Fixes Applied

- Added `After Pocket Internet to DN42 Border` to `docs/reader-knowledge.md`.

## Deferred Follow-Up Issues

- #52: convention retrofit after this audit.
- #53: IPv6 and ULA foundation before real DN42.
- #54: local-link discovery and packet observation.
- #55: firewall and packet-filtering foundation.
- #56: Pocket Internet DNS and naming foundation.
- #57: observability and operational troubleshooting foundation.

## What Does Not Need Immediate Rewrite

- The existing route-lookup and static-route chapters can remain IPv4-first.
- BIRD and BGP chapters do not need production DN42 policy yet; they already label lab-only shortcuts.
- WireGuard chapters can remain local-underlay labs while MTU/NAT/keepalive are deferred to a real-underlay chapter.
- Part 2 DN42 draft pages can stay roadmap/draft material until the missing foundations above exist.
