# DN42 Source Refresh

Reviewed on: 2026-06-20

Issue: #68

Primary sources:

- `dn42-getting-started`: https://dn42.cc/wiki/howto/getting-started/
- `dn42-registry`: https://git.dn42.dev/dn42/registry
- `dn42-registry-authentication`: https://dn42.cc/wiki/howto/registry-authentication/
- `dn42-bird2`: https://dn42.cc/wiki/howto/routing-daemons/bird2/
- `dn42-rpki`: https://dn42.cc/wiki/services/rpki/
- `dn42-network-settings`: https://dn42.cc/wiki/howto/network-settings/
- `dn42-wireguard`: https://dn42.cc/wiki/howto/tunnel/wireguard/
- `dn42-dns`: https://dn42.cc/wiki/services/dns/
- `dn42-dns-configuration`: https://dn42.cc/wiki/services/dns/configuration
- `dn42-new-dns`: https://dn42.cc/wiki/services/dns/new-dns
- `bird-docs`: https://bird.network.cz/
- `wireguard-quickstart`: https://www.wireguard.com/quickstart/
- `wireguard-wgquick`: https://man7.org/linux/man-pages/man8/wg-quick.8.html
- `wireguard-netns`: https://www.wireguard.com/netns/

Registry checkout reviewed:

- Commit: `eaa6af80248778d7e30677dd6aac62500600592c`
- Commit date: 2026-06-20 16:11:09 +0000
- Subject: `Merge pull request 'email change for 4242421810' (#6778) from sabrina/registry:master into master`
- Temporary checkout: `/private/tmp/dn42-registry-refresh-20260620/`

## Verdict

The June 15 registry, BIRD, and WireGuard notes remain directionally correct, but they should now be treated as superseded by this June 20 refresh for DN42-facing drafting.

Proceed with #12, #13, #14, #15, and #20 only if each chapter cites this note and the specific source notes it depends on. This refresh permits drafting. It does not remove the need to test chapter commands in a fixture or live-safe environment before publication.

## Registry and Registration Guidance

Current DN42 onboarding still expects registry changes through a fork, local edits, validation scripts, squashed commits, signed final commit, and pull request review.

The registry README still names the practical validation path:

- `./fmt-my-stuff MNTNER-MNT`
- `./check-my-stuff MNTNER-MNT`
- `./check-pol origin/master MNTNER-MNT`
- `./squash-my-commits -S --push`

The getting-started page still requires a usable `mntner` with authentication, and it still points readers toward signed commits. It also still warns strongly about registry privacy: submitted registry data should be treated as public and hard to fully remove after propagation.

Chapter constraints:

- #12 must include privacy and authentication warnings before object examples.
- #12 must not tell a reader to use the Gitea web editor for registry object changes.
- #12 must explain that free ASN and prefix availability is time-sensitive and must be checked at the moment of registration.
- #12 should teach route and route6 objects as required for announced prefixes, because they feed route-origin authorization checks.

## BIRD 2 and Route Policy Guidance

The current DN42 BIRD 2 page still uses BIRD 2 examples with explicit DN42 filters, ROA checks, import limits, and peer templates.

The important safe shape remains:

- import only DN42/federated ranges,
- reject self-originated prefixes on import,
- check ROA tables,
- reject when `roa_check(...) != ROA_VALID` in the DN42 example,
- set import limits,
- export only valid ranges and expected route sources such as `RTS_STATIC` and `RTS_BGP`,
- reject static routes from kernel export where those routes exist only to seed BIRD policy.

The official BIRD site now points to current 2.17.1 release context and also exposes BIRD 3.0 documentation. The book should choose BIRD 2 deliberately for DN42 examples unless a later source review decides to teach BIRD 3.

Chapter constraints:

- #14 must not reuse Pocket Internet prefix allowlists as DN42 policy.
- #14 must use source-backed import/export filters and explain ROA behavior.
- #14 must include syntax validation before starting or reloading BIRD.
- #14 must distinguish BIRD route state from Linux kernel route state and include kernel-route troubleshooting.
- #14 should treat public RTR services as bootstrap dependencies, not a final reliability design.

## WireGuard and Tunnel Guidance

The current DN42 WireGuard page still treats WireGuard as a point-to-point tunnel for BGP peering and recommends one WireGuard interface per peering so BGP, not WireGuard multi-peer selection, does routing decisions.

Current constraints to carry forward:

- Use one interface per DN42 peer in first teaching examples.
- Start with explicit `wg`/`ip` mechanics unless a chapter is specifically about `wg-quick`.
- If `wg-quick` is used with broad `AllowedIPs`, use `Table = off` so `AllowedIPs` does not install default or DN42-wide routes outside BGP control.
- `AllowedIPs` must include the DN42 ranges or inner destinations that the peer is expected to carry; next-hop-only `AllowedIPs` can make route lookup look correct while WireGuard refuses data-plane packets.
- Do not hard-code a universal MTU. Measure the peer path and subtract tunnel overhead as the DN42 page describes.
- Use `PersistentKeepalive = 25` only when NAT or stateful-firewall behavior requires an idle mapping to stay open.

Chapter constraints:

- #13 must warn against accidental default-route behavior before showing any broad `AllowedIPs`.
- #13 must include verification in layers: underlay endpoint, WireGuard handshake/counters, overlay route lookup, BGP session, then service traffic.
- #13 must include rollback that removes the interface and any routes or service files created by the example.

## Network Settings, Asymmetry, and Forwarding

The DN42 network settings page still warns that reverse-path filtering conflicts with DN42's asymmetric routing patterns. It also requires forwarding for IPv4 and IPv6 on router interfaces.

Current constraints to carry forward:

- DN42 router chapters must set and verify IPv4 and IPv6 forwarding intentionally.
- Reverse-path filtering must be disabled with attention to both `all` and interface-specific values.
- Do not drop forwarded packets solely because conntrack labels them invalid in asymmetric routing scenarios.
- Treat these as real-router settings with rollback and verification, not Pocket Internet namespace defaults.

Chapter constraints:

- #20 must keep a dedicated border/router boundary in the design.
- #20 must include explicit "what could leak?" checks before any future implementation advertises or forwards traffic.
- #14 and #20 must not blame BIRD before checking forwarding, rp_filter, route lookup, firewall, and return path.

## DNS and Split Resolver Guidance

DN42 DNS guidance now needs explicit source IDs in the project. This refresh adds:

- `dn42-dns`
- `dn42-dns-configuration`
- `dn42-new-dns`

Current DN42 DNS guidance says:

- running your own resolver is recommended for security and privacy,
- anycast recursive services exist for getting started,
- users should configure multiple recursive services for redundancy,
- split-horizon DNS forwards DN42-related zones to DN42 resolvers while normal DNS remains separate,
- resolver examples are implementation-specific,
- the registry is the authoritative source for active TLDs and service lists,
- current architecture separates recursive servers from delegation servers and includes DNSSEC support.

Chapter constraints:

- #15 must not replace public DNS globally without warning.
- #15 must distinguish local resolver, split forwarding, anycast recursive service, and full-recursion/delegation-server paths.
- #15 must treat resolver-specific examples as implementation-specific, not universal.
- #15 must include tests for public DNS remaining unaffected and `.dn42` names resolving through the intended path.

## Issue Annotation Requirements

The following DN42-facing issues should cite this note before implementation:

- #12: registry objects, authentication, privacy, validation scripts.
- #13: WireGuard peer model, `AllowedIPs`, `wg-quick` route behavior, MTU, keepalive.
- #14: BIRD 2 import/export policy, ROA validation, import limits, kernel export, network settings.
- #15: DNS anycast, split resolver configuration, resolver-specific examples, DNSSEC caveats.
- #20: border design, route-leak checks, forwarding/rp_filter/asymmetry, return path, no default route.

## Open Questions Before Publishing Commands

- Choose the default maintainer authentication path for the book: SSH Ed25519 signing, PGP, or both with one primary.
- Build a local registry fixture branch and run registry scripts against example objects before publishing #12 commands.
- Decide whether first DN42 peering examples are IPv6-only, dual-stack, or staged.
- Build and syntax-check BIRD configs used in #14 before publishing.
- Decide whether first tunnel examples use plain `wg`/`ip` only, with `wg-quick` deferred to a later convenience chapter.
- Choose the resolver implementation for #15's first split-DNS lab.
