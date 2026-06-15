# DN42 BIRD 2 Examples Review

Reviewed on: 2026-06-15

Primary sources:

- `dn42-bird2`: https://dn42.cc/wiki/howto/routing-daemons/bird2/
- `dn42-rpki`: https://dn42.cc/wiki/services/rpki/
- `bird-docs`: https://bird.network.cz/
- `dn42-network-settings`: https://dn42.cc/wiki/howto/network-settings/
- `dn42-historical-bird`: https://dn42.cc/wiki/historical/bird/

Local ignored cache:

- `research/cache/dn42-bird2.html`
- `research/cache/dn42-roa-services.html`
- `research/cache/bird-docs-rpki.html`
- `research/cache/dn42-network-settings.html`
- `research/cache/dn42-bird.html`

## What This Review Covers

This note records the current DN42 BIRD 2 example posture, safe filter defaults, ROA table guidance, and examples that should not be copied directly into the book.

Use this source set for:

- BIRD 2 peer template structure.
- DN42-specific import and export filters.
- DN42 ROA table and RPKI/RTR options.
- Kernel/static route handling assumptions.
- Warnings about stale Bird 1-era examples.

Do not use this source set alone for:

- Final production router configuration.
- Peer-specific policy.
- Distribution package freshness without checking the target OS release.
- A generated full config without running `bird -p -c <config>` or equivalent syntax validation.

## Safe Import Defaults

The current DN42 BIRD 2 page uses a conservative import posture:

- Accept only prefixes inside the configured DN42/federated address ranges.
- Reject the router's own prefixes on import.
- Run `roa_check()` against the IPv4 or IPv6 ROA table.
- Reject routes where `roa_check(...) != ROA_VALID`.
- Set an import limit, currently shown as `import limit 9000 action block`.

For chapter examples, teach the import filter as fail-closed for DN42 experiments unless the chapter explicitly explores reachability tradeoffs:

```bird
if is_valid_network() && !is_self_net() then {
  if (roa_check(dn42_roa, net, bgp_path.last) != ROA_VALID) then reject;
  accept;
}
reject;
```

IPv6 should use the same shape with `is_valid_network_v6()`, `is_self_net_v6()`, and `dn42_roa_v6`.

Important tradeoff:

- DN42's current example rejects both `ROA_INVALID` and `ROA_UNKNOWN` by checking for `!= ROA_VALID`.
- The official BIRD RPKI example rejects only `ROA_INVALID`.
- Treat the DN42 example as a stricter DN42-specific policy, not a generic BIRD/RPKI rule.
- If a teaching experiment relaxes to "reject invalid, accept unknown", label it as an explicit reachability experiment and explain the risk.

## Safe Export Defaults

The current DN42 BIRD 2 page exports only routes that are within valid DN42/federated ranges and whose BIRD route source is static or BGP:

```bird
export filter {
  if is_valid_network() && source ~ [RTS_STATIC, RTS_BGP] then accept;
  reject;
};
```

IPv6 should use `is_valid_network_v6()`.

Teach these export defaults:

- Never export a default route.
- Never export public Internet routes into DN42.
- Export only explicitly valid DN42/federated prefixes.
- Export only expected route sources, normally `RTS_STATIC` for owned aggregate rejects and `RTS_BGP` for transit.
- Keep owned aggregate reject routes in static protocols with `export none`; they exist to seed the route table, not to leak through the kernel protocol.
- In kernel protocols, use `import none` and reject `RTS_STATIC` on kernel export before setting `krt_prefsrc`.

Chapter examples should separate these ideas into named filters before building larger peer templates. That will make experiments easier to inspect and prevents accidental "accept all" behavior.

## ROA Table Guidance

Current DN42 guidance supports two approaches:

- Static ROA include files generated from registry-derived sources.
- RPKI/RTR sessions using a local or public RTR server.

Static ROA files:

- Define `roa4 table dn42_roa;`.
- Define `roa6 table dn42_roa_v6;`.
- Include Bird2-format generated files with static ROA protocols.
- Current listed Bird2 sources include:
  - `https://dn42.burble.com/roa/dn42_roa_bird2_4.conf`
  - `https://dn42.burble.com/roa/dn42_roa_bird2_6.conf`
  - `https://dn42.burble.com/roa/dn42_roa_bird2_46.conf`
  - `https://kioubit-roa.dn42.dev/?type=v4`
  - `https://kioubit-roa.dn42.dev/?type=v6`

RPKI/RTR:

- Use `protocol rpki` with both `roa4 { table dn42_roa; };` and `roa6 { table dn42_roa_v6; };` when validating both address families.
- DN42's BIRD 2 page says to add `import table;` to both BGP channels when using RTR so ROA table changes can affect filtered routes without a manual reload.
- The DN42 RPKI page recommends running your own validator for the most control, while also listing public RTR services for getting started.
- The official BIRD docs allow more than one RPKI protocol generally, but only one cache server per protocol.

Preferred teaching path:

- Start with static generated ROA include files for the first local experiment because the moving parts are visible.
- Add a later experiment that replaces static ROA files with a local RTR validator.
- Show `birdc configure` after static ROA updates.
- Show `import table;` when RTR is introduced.
- Treat public RTR servers as bootstrap dependencies, not as the final reliability design.

## Network Settings Adjacent to BIRD

The DN42 network settings page is not BIRD-specific, but it affects whether BGP-learned routes can actually forward traffic:

- Disable IPv4 reverse path filtering for DN42/asymmetric routing paths.
- Enable IPv4 and IPv6 forwarding.
- Do not drop forwarded packets solely because conntrack marks them invalid in asymmetric routing scenarios.
- Be cautious with DN42 IPs as BGP peer addresses when not using extended next hop and when the same IP is used for services.

These should appear near the first router bring-up experiment, before blaming BIRD filters for forwarding failures.

## Stale or Conflicting Examples to Flag

Do not copy these directly:

- The historical DN42 Bird page is explicitly Bird 1.x material and says Bird 1.6.x was expected to be EOL by the end of 2023.
- Historical examples include separate `bird`/`bird6` conventions and Bird1-format ROA files; the current BIRD 2 path should use BIRD 2 syntax.
- The historical page includes an advanced ROA update script with empty `roa4URL`/`roa6URL` placeholders and malformed URL interpolation in the cached rendering; treat it as stale contrast only.
- The current DN42 BIRD 2 page still contains multiple ROA approaches on the same page: static include files, RTR replacement, stayrtr, public RTR, and generated Bird2 files. A chapter must choose one path per experiment and say which older/conflicting blocks are being replaced.
- The current BIRD 2 example has placeholder comments containing `interface <NEIGHBOR_INTERFACE>;****`; do not preserve the trailing marker in book examples.
- Debian package guidance in the BIRD 2 page calls out Debian 11 Bullseye and BIRD 2.0.7. Treat distribution version notes as time-sensitive and refresh before publishing.
- The BIRD 2 page notes that BIRD versions before 2.0.8 lack IPv6 extended next hop support for IPv4 destinations and cannot automatically update filtered BGP routes when an RPKI source changes. Do not build extended next-hop or RTR experiments on older BIRD 2.

## Open Questions Before Chapter Drafting

- Decide whether the first BIRD experiment is IPv6-only or dual-stack; the DN42 example is dual-stack but an IPv6-only first chapter may be clearer.
- Build a small fixture config and run BIRD syntax validation before publishing any full config.
- Decide how strict the first import policy should be for the learner's first peering: DN42-strict `ROA_VALID` only, or a visible experiment comparing invalid-only rejection to strict rejection.
- Confirm current public RTR endpoints and generated ROA URLs immediately before release.
