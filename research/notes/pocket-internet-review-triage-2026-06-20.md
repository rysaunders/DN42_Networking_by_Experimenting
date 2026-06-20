# Pocket Internet Review Triage

Reviewed on: 2026-06-20

Issue: #61

Inputs:

- #58 diagram visual-language audit
- #59 beginner review
- #60 technical review

## Triage Decision

Pocket Internet Part 1 is conceptually strong, but it should not be treated as ready for DN42-facing chapter drafting until a short hardening pass lands.

No P0 lab correctness issue was found. The blocking issues are:

- runbook command correctness,
- local-link sequencing,
- lab continuity and requirements,
- BIRD/BGP config comprehension and policy caveats,
- state snapshots in the command-heavy BIRD/WireGuard chapters,
- source refresh before real DN42 procedure work.

## Follow-Up Issues Created

| Issue | Title | Purpose |
| --- | --- | --- |
| #62 | Fix Pocket Internet runbook and safety command correctness | Fix BIRD socket paths, stale names, and host-vs-namespace command shapes. |
| #63 | Move local-link observation earlier in Part 1 | Address the beginner-blocking sequencing issue around connected routes and local-link delivery. |
| #64 | Standardize Part 1 lab requirements and checkpoint resume paths | Reduce rebuild friction while preserving manual-first learning. |
| #65 | Harden BIRD/BGP config teaching and lab policy caveats | Make config structure clearer and label lab filters as prefix allowlists, not DN42 policy. |
| #66 | Add BIRD/BGP and WireGuard state snapshots | Reduce command-heavy cognitive load and clarify `AllowedIPs` failure behavior. |
| #67 | Run targeted Part 1 re-review after hardening fixes | Confirm the hardening pass fixed the checkpoint findings before DN42 drafting. |
| #68 | Refresh DN42 sources before implementation chapters | Refresh volatile DN42 guidance before real registry, WireGuard, BIRD, DNS, or border procedures. |

## P1 Finding Coverage

| Finding | Disposition |
| --- | --- |
| Local-link observation arrives too late | Assigned to #63. |
| Lab continuity and rebuild burden are too high | Assigned to #64. |
| BIRD/BGP config density risks paste-without-understanding | Assigned to #65 and supported by #66. |
| Lab requirements are inconsistent | Assigned to #64. |
| Observability runbook BIRD commands do not match lab sockets | Assigned to #62. |
| Observability runbook has stale namespace/protocol names | Assigned to #62. |
| BGP import/export filters are lab prefix allowlists, not DN42 policy | Assigned to #65 and #68. |
| DN42-facing pages must stay blocked until current-source refresh | Assigned to #68 and annotated on #12, #13, #14, #15, and #20. |

## Deferred Items

Tooltip density, restrained human tone, start-page effort expectations, route-selection transition polish, and observability field-guide positioning are deferred into the hardening issues where they naturally fit. They should not become standalone issues unless the targeted re-review finds they still block comprehension.

## DN42 Readiness

Part 1 is not ready to serve as the basis for DN42 implementation chapters today. It is close enough that the remaining work should be a bounded hardening pass, not a rewrite.

DN42-facing issues remain open, but they should wait behind:

1. #62 through #66,
2. #67 targeted re-review,
3. #68 DN42 source refresh.

After those pass, the likely next DN42-facing issue is #12, the registry objects chapter.
