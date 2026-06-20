# Pocket Internet Targeted Re-Review

Reviewed on: 2026-06-20

Issue: #67

Scope:

- `docs/safety.md`
- `docs/reader-knowledge.md`
- `docs/part-01-first-principles/index.md`
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

Review stance: targeted follow-up to the P1 findings from #59 and #60 after issues #62 through #66 landed. This is not a full rewrite review.

## Verdict

Part 1 is ready to serve as the conceptual base for DN42-facing chapter drafting.

It is not yet ready for DN42 implementation commands. Real DN42 registry, peer, WireGuard, BIRD, DNS, and border procedures remain blocked on #68, the DN42 source refresh. That is the right boundary: Pocket Internet can now explain the model, but current-source review must still govern live-network instructions.

## P1 Finding Coverage

| Finding from #59/#60 | Disposition after hardening |
| --- | --- |
| Local-link observation arrives too late | Fixed by #63. The local-link observation chapter now appears immediately after addresses and prefixes, and downstream metadata was updated. |
| Lab continuity and rebuild burden are too high | Partially fixed by #64. Lab requirement blocks and dependent checkpoint/resume language are now standardized. The manual-first/repeat-script split is clear enough for v0.1. |
| BIRD/BGP config density risks paste-without-understanding | Fixed for v0.1 by #65. The BGP chapter now teaches config anatomy before the first full config and labels each decision boundary. |
| Lab requirements are inconsistent | Fixed by #64. Part 1 hands-on chapters now have consistent preflight expectations. |
| Observability runbook BIRD commands do not match lab sockets | Fixed by #62. Runbook command shapes now use lab control sockets where appropriate. |
| Observability runbook has stale namespace/protocol names | Fixed by #62. Stale `pocket-v6-left` and `bgp_as2` examples were removed or clarified. |
| Lab BGP filters risk being mistaken for real peer policy | Fixed for Part 1 by #65. The filters are now explicitly named as lab-only prefix allowlists, not DN42 policy. |
| Long command-heavy chapters need more state snapshots | Fixed for v0.1 by #66. BIRD, BGP, WireGuard, and BGP-over-WireGuard chapters now include state snapshots at major transitions. |
| WireGuard `AllowedIPs` failure mode needs stronger guidance | Fixed by #66. The BGP-over-WireGuard chapter now states that route lookup can point at `wg23` while WireGuard refuses an inner destination missing from `AllowedIPs`. |
| DN42-facing pages must stay blocked until source refresh | Still open by design. #68 is the active gate before real DN42 procedure drafting. |

## Remaining Non-Blocking Risks

- Some chapters are still long. They are workable for v0.1 because state snapshots, lab requirements, and validation scripts now give readers better landmarks.
- Tooltip density may still need visual polish after more real reading. It is not a conceptual blocker.
- The observability chapter may eventually work better as a field guide, but it is technically useful and no longer has the command-shape bugs that made it risky.
- The first-principles chapters teach enough to approach DN42 concepts, not enough to operate a real node without the later source-backed DN42 chapters.

## DN42 Readiness Decision

Proceed with DN42-facing drafting only after #68 refreshes the volatile DN42 sources and annotates the relevant implementation issues.

No new blocker issue is required from this targeted re-review. The remaining blocker is already tracked as #68.

## Verification

- Confirmed #62 through #66 are closed.
- Confirmed the Part 1 nav order places local-link observation before static routing.
- Confirmed Part 1 hands-on chapters use `Lab Requirements` instead of plain `Lab` headings.
- Confirmed BGP policy caveats and WireGuard `AllowedIPs` failure guidance are present.
