# Pocket Internet Technical Review

Reviewed on: 2026-06-20

Issue: #60

Scope:

- `docs/safety.md`
- `docs/pocket-internet.md`
- `docs/pocket-internet-dn42-interconnect.md`
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
- `experiments/labs/*/run.sh`
- `experiments/transcripts/*.txt`
- `research/sources.yml`

Review stance: technical correctness, Linux behavior, containment, and real-network safety implications. This review intentionally does not score beginner-friendliness.

## Verdict

No P0 technical issue was found in the contained Pocket Internet labs. The main Linux networking model is defensible: namespaces isolate network stacks, veth pairs act as local links, connected routes appear from interface addresses, route lookup is separated from packet movement, BIRD route state is separated from Linux kernel route state, BGP is taught as dynamic route exchange, and WireGuard is framed as a link rather than as BGP itself.

The highest-risk technical problem is in the generalized runbook layer, not the lab scripts: some runbook commands no longer match the custom BIRD sockets and protocol names used by the labs. That is a correctness bug because the command examples can fail even when the lab is healthy.

The other major risks are safety carryover risks. Several lab simplifications are acceptable inside Pocket Internet but must not become the shape of DN42-facing guidance without stronger caveats, source refresh, and peer-specific policy.

## P1 Findings

### 1. Observability runbook BIRD commands do not match lab BIRD sockets

Type: correctness bug.

Impact: `15-observability-and-troubleshooting.md` should not be used as a basis for DN42-facing troubleshooting until corrected.

The BIRD labs start each BIRD instance with a custom control socket:

- `06-bgp-before-dn42.md` lines 580-604 uses `-s /tmp/pocket-internet-bgp/pocket-as*.ctl`.
- `10-bgp-over-wireguard.md` lines 724-743 uses `-s /tmp/pocket-internet-wireguard-link/pocket-as*.ctl`.
- The transcripts confirm the same shape, for example `experiments/transcripts/pocket-internet-bgp-20260617T191953Z.txt` lines 157-173.

But the observability runbook shows:

- `15-observability-and-troubleshooting.md` lines 195-199:

  ```sh
  ip netns exec pocket-as1 birdc show protocols
  ip netns exec pocket-as1 birdc show route
  ip netns exec pocket-as1 birdc show route 172.20.3.1/32
  ```

Those commands rely on BIRD's default control socket path. In these labs, that default socket is not where the manually started BIRD processes listen. The technically correct lab command must include `-s <lab socket>`.

Recommended fix:

- Replace generic BIRD commands in the runbook with lab-shaped examples:

  ```sh
  ip netns exec pocket-as1 birdc -s /tmp/pocket-internet-bgp/pocket-as1.ctl show protocols
  ip netns exec pocket-as1 birdc -s /tmp/pocket-internet-bgp/pocket-as1.ctl show route
  ```

- For generic DN42-facing guidance, say explicitly that the socket path depends on whether BIRD is system-managed or manually started.

Related issue:

- `safety.md` lines 56-61 also shows generic `birdc show protocols` and `birdc show route`. That is acceptable only if framed as system-BIRD shape, not as a direct Pocket Internet lab command.

### 2. Observability runbook contains stale namespace and protocol names

Type: correctness bug.

Impact: same as above: the runbook needs correction before it is treated as operational guidance.

Examples:

- `15-observability-and-troubleshooting.md` line 163 uses `pocket-v6-left`, but the IPv6 chapter uses `pocket-v6-a` and `pocket-v6-b`.
- `15-observability-and-troubleshooting.md` lines 201-205 uses protocol name `bgp_as2`, but the BGP chapters use names such as `to_as2` and `to_as3`.

Recommended fix:

- Replace stale names with names from the actual Part 1 labs.
- Add one sentence explaining that protocol names are local labels from the BIRD config, not universal BIRD keywords.

### 3. BGP import/export filters are safe only as lab prefix allowlists

Type: safety caveat, not a local lab bug.

Impact: `06-bgp-before-dn42.md` should not be used as a basis for DN42 import/export policy until this is made explicit.

The BGP chapter correctly uses narrow filters:

- `06-bgp-before-dn42.md` lines 360-374 accepts and exports only the four service loopbacks.
- Lines 415-418 warns that `protocol kernel export all` is lab-only convenience and separates BGP export from kernel export.

That is good containment for a closed lab. It is not complete routing policy.

The filter permits a prefix if it is one of four expected prefixes. It does not validate:

- which neighbor is allowed to announce which prefix,
- whether the AS path is plausible,
- whether the origin AS matches expected ownership,
- whether a route should be preferred or de-preferred,
- whether a peer is leaking another peer's route back.

In Pocket Internet, that simplification is acceptable because every namespace is under lab control. In DN42-facing chapters, prefix allowlists alone are not enough to teach safe policy.

Recommended fix:

- Add a technical warning near the first BGP filter:

  > This lab filter is a prefix allowlist, not origin validation or complete peer policy.

- Later DN42 chapters must replace this with source-refreshed DN42 policy: authorized prefixes, peer-specific import/export, route limits, ROA/RPKI-like checks where applicable, and export inspection before session enablement.

### 4. DN42-facing pages correctly defer implementation, but must stay blocked until current-source refresh

Type: safety boundary.

Impact: `pocket-internet-dn42-interconnect.md` is safe as a design page, but should not be converted into commands without fresh source review.

The page is appropriately conservative:

- Lines 34-45 explicitly say it is not an implementation guide and that Pocket Internet routes are not exported by default.
- Lines 145-158 define a mandatory border checklist.
- Lines 205-216 call out return path and lab-only source-address problems.

The technical risk is future drift. DN42-facing guidance depends on current DN42 registry practice, BIRD examples, WireGuard expectations, DNS resolver expectations, and rp_filter/MTU behavior. `research/sources.yml` marks the DN42 sources as `research-required`, which is the right status.

Recommended rule:

- No DN42-facing command chapter should be promoted beyond draft until the relevant `research-required` DN42 sources are refreshed and cited in a chapter-local review note.

## P2 Findings

### 5. WireGuard `AllowedIPs` explanation is technically sound, but needs a stronger "this is not route policy" warning before DN42

Type: safety caveat.

The WireGuard chapters handle a subtle topic better than many beginner guides:

- `09-wireguard-as-a-link.md` lines 52-58 names `AllowedIPs` as peer selection and packet allow list.
- Lines 334-344 explains that the first lab allows only the overlay neighbor.
- `10-bgp-over-wireguard.md` lines 394-403 explains that raw `wg set` does not install the BGP-learned routes, while tools such as `wg-quick` may install routes from `AllowedIPs`.

That is technically defensible.

The remaining risk is carryover into real peers. In the BGP-over-WireGuard lab, `AllowedIPs` is deliberately broadened to include remote service loopbacks:

- `10-bgp-over-wireguard.md` lines 365-385 configures peer `allowed-ips` lists.
- Lines 394-403 explains why.

This is useful for showing WireGuard cryptokey routing. It also means a route can be correct in Linux but fail at WireGuard if the inner destination is not covered by `AllowedIPs`.

Recommended fix:

- Add a short "AllowedIPs failure mode" box before the first BGP-over-WireGuard route test:

  > If Linux routes a packet to `wg23` but WireGuard has no peer whose `AllowedIPs` covers the inner destination, the tunnel will not carry that packet.

- Keep later DN42 WireGuard guidance blocked on source refresh for MTU, persistent keepalive, NAT traversal, `wg-quick` route behavior, and peer expectations.

### 6. IPv6 ULA chapter is technically conservative, but it avoids link-local and router-advertisement details that DN42 chapters may need

Type: scoped omission, not a current bug.

The IPv6 chapter is safe for its stated purpose:

- `12-ipv6-ula-foundation.md` lines 122-143 explains IPv6 prefix length and `/64` local-link habit.
- Lines 144-163 correctly frames ULA as private IPv6 space and denies lab authorization.
- Lines 446-460 explicitly separates IPv4 and IPv6 route tables.
- Lines 472-483 warns that BIRD IPv4 policy is not automatically IPv6 policy.

The chapter intentionally leaves link-local addresses, router advertisements, BIRD IPv6 channel syntax, and real DN42 registry workflow as fuzzy topics in lines 584-595. That is acceptable for Part 1.

Constraint for later work:

- Do not let later DN42 chapters assume this chapter is enough for production-shaped IPv6. Before real DN42 IPv6 examples, add current-source-backed guidance for IPv6 BIRD channels, prefix authorization, filters, and route export checks.

### 7. nftables chapter is correct for input filtering, but does not teach forwarding policy

Type: scoped omission, not a current bug.

The packet-filtering lab is technically coherent:

- `13-packet-filtering-foundation.md` lines 276-310 creates an `inet` table with an `input` chain, default drop policy, loopback accept, TCP/8080 accept, and ICMP drop.
- Lines 362-371 accurately states what the checks prove and do not prove.
- Lines 459-469 explicitly defers forwarding-chain policy and production firewall design.

This is fine for a service endpoint lab. It is not enough for a router or DN42 border.

Constraint for later work:

- A DN42 border or forwarding chapter must add forward-chain policy, established/related handling where appropriate, interface scoping, counters, and rollback. It should not copy the input-chain-only lab as border firewall guidance.

### 8. DNS chapter is correct as a local resolver lab, but `.dn42` guidance remains intentionally absent

Type: scoped omission, not a current bug.

The DNS chapter is careful:

- `14-dns-and-naming-foundation.md` lines 120-124 confines resolver changes to `/etc/netns/pocket-dns-client`.
- Lines 189 uses `.test`, which is appropriate for local testing.
- Lines 327-345 explains the namespace-specific resolver file.
- Lines 546-549 says `.dn42` resolver guidance needs fresh source review.

No technical issue found in the local lab model.

Constraint for later work:

- Do not treat this as `.dn42` split-DNS implementation guidance. Later chapters need current DN42 resolver/source review and should distinguish host resolver configuration, namespace resolver configuration, and service-level resolver behavior.

### 9. `ip_forward` scope is correct in the labs, but the book should keep warning against host-wide sysctl carryover

Type: safety caveat.

The routing labs enable forwarding inside namespaces, for example:

- `06-bgp-before-dn42.md` lines 279-285.
- `10-bgp-over-wireguard.md` lines 305-311.

That is appropriate in the lab because each namespace has its own network stack and is removed by rollback.

The safety page already says not to apply host-wide sysctl changes from real-network examples to early local labs:

- `safety.md` lines 173-184.

Keep that warning. Later real-node chapters must explain exact sysctl scope, verification, and rollback.

## P3 Findings

### 10. Some generic safety commands should distinguish host context from namespace context

Type: polish / operational precision.

`safety.md` lines 38-69 gives useful baseline commands. Because Part 1 uses both host-context and namespace-context checks, a few examples could be clearer:

- `birdc show protocols` may mean system BIRD on a real node, but not the manually started BIRD instances in Pocket Internet.
- `wg show` on the host will not show namespace-local WireGuard interfaces unless run in the namespace.

Recommended quick edit:

- Split generic safety examples into:
  - host/system-managed command shape,
  - Pocket Internet namespace command shape.

### 11. Transcripts support the main lab claims

Type: positive finding.

The transcript set covers the major claims:

- `pocket-internet-bgp-20260617T191953Z.txt` shows BIRD sessions, BGP route selection, kernel route export, and ping reachability.
- `wireguard-point-to-point-20260618T213251Z.txt` shows WireGuard peer configuration and tunnel checks.
- `pocket-internet-wireguard-link-20260618T112938Z.txt` shows BGP over the WireGuard overlay.
- `local-link-observation-20260620T000000Z.txt`, `ipv6-ula-foundation-20260620T000000Z.txt`, `packet-filtering-foundation-20260620T000000Z.txt`, and `dns-and-naming-foundation-20260620T000000Z.txt` back the newer foundation chapters.

The placeholder-looking `20260620T000000Z` timestamps are unusual but not technically harmful. If these are generated transcripts rather than real-time transcripts, the project should keep being explicit about what was actually run.

## Chapters Not Ready As DN42 Bases Until Fixed

- `15-observability-and-troubleshooting.md`: not ready until BIRD socket/protocol examples and stale namespace names are corrected.
- `06-bgp-before-dn42.md`: good lab, but not ready as policy basis until it explicitly labels the filters as lab prefix allowlists, not origin validation or complete DN42 policy.
- `09-wireguard-as-a-link.md` and `10-bgp-over-wireguard.md`: good local tunnel labs, but not ready as DN42 WireGuard procedure until MTU, NAT/keepalive, `wg-quick`, `rp_filter`, and current peer expectations are source-refreshed.
- `13-packet-filtering-foundation.md`: good endpoint filter lab, but not ready as border firewall procedure until forwarding-chain policy is taught.
- `14-dns-and-naming-foundation.md`: good local DNS lab, but not ready as `.dn42` resolver guidance until DN42 DNS sources are refreshed.
- `pocket-internet-dn42-interconnect.md`: safe as a design/safety contract, not ready as a procedure.

## Strengths To Preserve

- Local labs are contained in namespaces and repeatedly prove rollback.
- Route lookup, packet movement, service listener, filter policy, DNS resolution, WireGuard state, and BIRD/BGP state are separated instead of collapsed into "network works."
- Lab ASNs and prefixes are repeatedly marked lab-only.
- WireGuard is correctly presented as a link that still needs routing above it and an underlay beneath it.
- The DN42 border page is conservative and default-deny by design.

## Recommended Remediation Order

1. Fix the observability runbook command bugs.
2. Add explicit BGP policy caveats around lab prefix allowlists.
3. Split safety command examples into system-managed and namespace-lab forms.
4. Add a WireGuard `AllowedIPs` failure-mode box in the BGP-over-WireGuard chapter.
5. Keep DN42-facing implementation issues blocked on fresh source review.
6. After those fixes, run a targeted technical re-check before writing real DN42 peer chapters.

## Review Boundary

This issue did not change lesson content. It records technical findings and safety constraints for the next hardening pass.
