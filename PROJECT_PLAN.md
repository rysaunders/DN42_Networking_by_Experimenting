# Building a Small Internet: Networking by Experimenting with DN42

This is a planning document for a Git-based book/site that teaches networking by building, breaking, observing, and explaining how a small Internet emerges from computers exchanging routes.

The project should not become a command cookbook. Every chapter should connect an observable lab result to a networking concept, then show how DN42 practice and the public Internet differ.

Pocket Internet is the laboratory, not the destination. Before readers touch public DN42, they build a small local Internet on one Linux machine. Namespaces act as routers, veth pairs act as links, loopbacks act as advertised service addresses, BIRD acts as the routing speaker, and WireGuard later replaces one local link with an encrypted tunnel.

DN42 is the bridge from the laboratory to a living routing ecosystem. The advanced payoff is not publishing the lab by default; it is understanding the border well enough that real DN42 peering, route policy, and service operation feel like the same mechanics at larger scale.

Guiding question for every chapter:

> How does an Internet emerge from a collection of computers exchanging routes?

## 1. Recommended Publishing Stack

### Options Compared

| Stack | Strengths | Weaknesses | Fit for this project |
| --- | --- | --- | --- |
| mdBook | Very simple book model, fast builds, Markdown-first, built-in search, familiar from the Rust book. The mdBook docs describe it as suitable for tutorials, course materials, and clean navigable books. Source: [mdBook documentation](https://rust-lang.github.io/mdBook/). | Navigation is book-linear. Rich callouts, diagrams, tabs, and structured reference pages require plugins or custom styling. | Good if the project is mostly a linear book and wants minimal moving parts. |
| MkDocs Material | Markdown-first, strong navigation, built-in search, admonitions, code annotations, diagrams, tabs, footnotes, social cards, and GitHub Pages deployment. The project describes itself as searchable, customizable, responsive, open source documentation. Sources: [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) and [MkDocs deployment docs](https://www.mkdocs.org/user-guide/deploying-your-docs/). | Python dependency stack. Some advanced Material features are sponsorware; the free core is enough for this project. | Best fit: serious docs site plus book-like learning path, with reusable chapter templates and strong callouts. |
| Docusaurus | Strong React ecosystem, versioning, docs plus blog, rich components, and GitHub Pages support. Source: [Docusaurus deployment docs](https://docusaurus.io/docs/deployment). | Node/React complexity is higher than needed. Custom components can pull the project toward app development instead of writing and reproducible labs. | Good if the project later needs interactive React demos, but too much surface area for v0.1. |
| Quartz | Excellent for linked notes and knowledge gardens, especially Obsidian-style content. | Less ideal for a guided curriculum with strict lab order, testable examples, and chapter templates. | Useful for private research notes, not the main publication target. |
| GitBook and hosted alternatives | Polished hosted editing, comments, AI and collaboration features, Git sync. Source: [GitBook documentation](https://gitbook.com/docs/). | Less transparent and reproducible than a pure static-site repo. Free/hosted constraints can change. | Consider only as a mirror later; do not make it the source of truth. |

### Recommendation

Use **MkDocs Material** as the primary publishing stack and **GitHub Pages** as the primary hosting target.

Reasons:

- It supports both a guided book path and a reference-style site.
- It gives chapter authors useful teaching primitives: admonitions, tabs, code annotations, diagrams, tables, and built-in search.
- It is static and free to host on GitHub Pages, with GitHub Actions building the site from `main`.
- It fits the working agreement: Python dependencies can be managed with `uv`.
- It keeps the source plain Markdown and YAML, which is easy for future LLMs to regenerate.
- The same GitHub repository can hold the publication source, project issues, milestone tracking, pull requests, and release tags.

Use **mdBook only if the project intentionally narrows to a linear book** and rejects site-like reference sections. Avoid Docusaurus for v0.1 unless interactive React components become mandatory.

### Proposed Repository Layout

```text
networking-by-experimenting-with-dn42/
  README.md
  AGENTS.md
  pyproject.toml
  uv.lock
  mkdocs.yml
  docs/
    index.md
    start-here.md
    glossary.md
    safety.md
    part-01-first-principles/
      index.md
      01-linux-networking.md
      02-addressing-and-subnets.md
      03-pocket-internet-static-routing.md
      04-routing-tables.md
      06-bgp-before-dn42.md
      07-operate-a-service.md
      08-links-tunnels-underlays-overlays.md
      09-wireguard-as-a-link.md
    part-02-first-dn42-node/
      index.md
      01-registry-objects.md
      02-first-wireguard-peer.md
      03-first-bird-session.md
      04-kernel-routes.md
      05-dn42-dns.md
      06-first-service.md
    part-03-routing-policy/
      index.md
      01-second-peer.md
      02-route-selection.md
      03-import-export-filters.md
      04-roa-validation.md
      05-convergence-failures.md
    part-04-services-and-operations/
      index.md
      01-web-service.md
      02-looking-glass.md
      03-authoritative-dns.md
      04-monitoring.md
      05-common-failures.md
    part-05-advanced-topologies/
      index.md
      01-anycast.md
      02-two-region-topology.md
      03-traffic-engineering.md
      04-bgp-communities.md
      05-weird-useful-services.md
    appendices/
      command-reference.md
      bird-reference.md
      wireguard-reference.md
      dns-reference.md
      lab-environment.md
      citation-index.md
    templates/
      chapter-template.md
      experiment-template.md
      research-note-template.md
  experiments/
    lab-manifests/
    transcripts/
    expected-output/
  research/
    README.md
    sources.yml
    notes/
    snapshots/
    cache/
      README.md
  scripts/
    validate_markdown.py
    validate_commands.py
    check_links.py
    capture_transcript.py
  diagrams/
    source/
    generated/
  .github/
    workflows/
      docs.yml
      links.yml
      issue-triage.yml
```

### GitHub Repository and Pages Target

The canonical repository is:

- [rysaunders/DN42_Networking_by_Experimenting](https://github.com/rysaunders/DN42_Networking_by_Experimenting)

Use GitHub this way:

- GitHub Pages publishes the built MkDocs site from GitHub Actions.
- GitHub Issues track chapter work, research work, experiment testing, safety reviews, and broken links.
- GitHub Milestones group work into `v0.1`, `v0.2`, and later releases.
- GitHub Projects can provide the board view, but Issues remain the durable source of truth.
- Pull requests are the review boundary for new chapters, command changes, and source refreshes.
- Release tags such as `v0.1.0` mark reviewed publication snapshots.

Recommended Pages workflow:

- On pull requests: run `uv run mkdocs build --strict`, Markdown checks, source registry validation, and link checks where practical.
- On pushes to `main`: build and deploy to GitHub Pages using `actions/deploy-pages`.
- Do not commit the generated `site/` directory. Treat it as build output.

## 2. Book Structure

Every chapter should use the same visible structure:

- Concept
- Why it matters
- Lab / experiment
- Expected observations
- Troubleshooting notes
- How the real Internet does this
- References and research notes

### Part 1: From Host to Router

Reader outcome: the reader can explain what a Linux router is doing before DN42 enters the picture.

You know it works when:

- The reader can predict which interface a packet will leave.
- The reader can explain source address selection at a basic level.
- The reader can read a route table and identify default, connected, and blackhole routes.

Chapters:

1. **Linux as a Router**
   - Concept: interfaces, addresses, forwarding, routes, packet path.
   - Lab: create two network namespaces and route between them.
   - Expected observations: `ip addr`, `ip route`, `ping`, packet counters change.
   - Real Internet: routers forward by table lookup, not by "being connected to the Internet."
   - References: Linux `ip-route(8)` manual, kernel forwarding docs. Source: [ip-route(8)](https://man7.org/linux/man-pages/man8/ip-route.8.html).

2. **Addresses, Prefixes, and Longest Match**
   - Concept: IPv4, IPv6, CIDR, ULA, longest-prefix match.
   - Lab: add overlapping routes and observe selection.
   - Expected observations: more-specific routes win.
   - Real Internet: BGP advertises prefixes; forwarding uses the best installed route.
   - References: RFC 4193 for IPv6 ULA. Source: [RFC 4193](https://www.rfc-editor.org/rfc/rfc4193).

3. **Pocket Internet with Static Routes**
   - Concept: a small local Internet, AS-shaped namespaces, point-to-point links, loopback service addresses, and explicit routes.
   - Lab: build a four-namespace topology and make loopback services reachable with static routes.
   - Expected observations: pings follow expected paths; link failure breaks reachability until routes are changed.
   - Real Internet: static routing does not scale, but it makes reachability, return paths, and failure behavior visible before BGP.

4. **Routing Tables and Policy Routing**
   - Concept: main table, local table, custom tables, rules.
   - Lab: send traffic through different tables using `ip rule`.
   - Expected observations: `ip route get` changes when rules change.
   - Real Internet: routers use multiple RIB/FIB concepts and policy; Linux exposes a simplified but useful model.
   - References: `ip-route(8)`.

### Part 2: Build the Pocket Internet

Reader outcome: the reader sees a tiny Internet emerge from linked routers and route tables.

Chapters:

1. **Multiple Routers and Static Routes**
   - Concept: multiple routers, loopback service addresses, forward path, return path.
   - Lab: build the Pocket Internet static routing topology.
   - Expected observations: service loopbacks are reachable only after explicit routes exist.

2. **Route Selection and Static Routing Limits**
   - Concept: static routes do not react to topology changes.
   - Lab: break a selected link, observe failure, repair manually, then compare route lookups before and after the repair.
   - Expected observations: an alternate physical path is not useful until routing points to it.

### Part 3: Add a Routing Control Plane

Reader outcome: the reader understands dynamic routing as route-table automation.

Chapters:

1. **BIRD as a Route Manager**
   - Concept: routing daemon, route selection, kernel export.
   - Lab: install routes through BIRD before BGP.

2. **BGP Before DN42**
   - Concept: neighbors exchange reachability.
   - Lab: add BGP sessions to Pocket Internet and advertise loopback service prefixes.

3. **Withdrawal, Convergence, and Path Choice**
   - Concept: routes can disappear, alternatives can win, and policy can influence selection.
   - Lab: break links, withdraw prefixes, and observe route changes.

### Part 4: Replace Lab Links with Real Links

Reader outcome: the reader understands that routing stays the same when a local cable becomes a tunnel.

Chapters:

1. **Links, Tunnels, Underlays, and Overlays**
   - Concept: a tunnel is a link-shaped thing carried inside another network.

2. **Replace a Pocket Internet Link with WireGuard**
   - Lab: replace one Pocket Internet veth link with WireGuard.

3. **Underlay, Overlay, and MTU**
   - Concept: packets inside packets, endpoint reachability, and packet size limits.
   - Lab: observe clear overlay traffic and encrypted underlay traffic.

### Part 5: Design the DN42 Border

Reader outcome: the reader understands the boundary between the lab-built network and a living routing ecosystem before configuring real peers.

Chapters:

1. **DN42 Registry Objects**
   - Concept: maintainer, person, ASN, prefixes, route objects, DNS objects.
   - Lab: prepare registry changes locally; do not submit until validated.

2. **Pocket Internet to DN42 Border**
   - Concept: border router, containment, return path, import/export filters.
   - Lab: design the border before public peering; do not export Pocket Internet routes by default.

3. **First Real Peer**
   - Concept: WireGuard peer plus BGP neighbor on the DN42 side of the border.
   - Lab: configure one real DN42 peer with conservative filters.

### Part 6: Operate Services Across the Interconnect

Reader outcome: the reader operates services across a real/lab network boundary.

Chapters:

1. **DN42 DNS**
   - Concept: split DNS and resolver routing.

2. **First Reachable Service**
   - Concept: service reachability requires forward path, return path, policy, and firewall alignment.

3. **Monitoring, Rollback, and Safety**
   - Concept: route leaks, export policy, logs, counters, and rollback drills.

### Later DN42 and Operations Notes

Keep the DN42 chapter issues open, but treat them as later-phase work until the Pocket Internet foundation and border model are clear.

Later DN42 chapters still need to cover:

- registry objects: maintainer, person, ASN, prefixes, route objects, and DNS objects,
- first real WireGuard peer: endpoint, keys, keepalive, underlay/overlay separation, and MTU,
- first real BIRD session: BGP neighbor, local ASN, peer ASN, import filters, export filters, and kernel export,
- DN42 DNS: split DNS, `.dn42` forwarding, resolver-specific behavior, and current resolver recommendations,
- first DN42 service: source address selection, return path, firewall policy, peer filtering, and service reachability,
- multi-peer policy: route selection, convergence, local preference, import/export filters, ROA-style validation, and communities,
- operations: looking glass, monitoring, authoritative DNS, rollback drills, and route-leak prevention,
- advanced topologies: anycast, multi-site behavior, traffic engineering, and operational tradeoffs.

## 3. Research Plan

### Source Categories and Questions

| Source category | Likely sources | Questions to answer |
| --- | --- | --- |
| DN42 wiki/docs | DN42 wiki pages for getting started, WireGuard, BIRD, DNS, services, communities. | What is current recommended practice? Which examples are stale? Which commands are Linux-specific? What warnings do maintainers emphasize? |
| DN42 registry docs | Registry README, schema explorer, registry scripts, example pull requests. | What objects are required? What validation scripts must authors run? What auth methods are accepted? What privacy warnings should be shown? |
| BIRD 2 docs | Official BIRD user guide and examples. | What is current BIRD 2 syntax? How should kernel protocol, device protocol, static protocol, BGP protocol, import/export filters, and ROA tables be configured? |
| WireGuard docs | WireGuard quick start, `wg(8)`, `wg-quick(8)`, systemd-networkd WireGuard docs. | Which commands are minimal and explicit? When should persistent keepalive be used? How do AllowedIPs affect routing? |
| Linux networking docs | `iproute2`, man7 pages, kernel docs, nftables docs. | How do route tables, rules, source address selection, forwarding, and firewall hooks interact? |
| systemd-networkd and resolved docs | Official systemd manual pages. | How should interfaces and split DNS be configured declaratively? What differs by systemd version? |
| RIPE/RPKI/ROA background | RIPE NCC route origin authorization pages, RFC 6811. | What is ROA conceptually? How does DN42's registry-derived ROA-like validation differ from public RPKI? |
| BGP path selection | RFC 4271, BIRD docs, vendor-neutral explanations. | What is standard BGP decision behavior? What is implementation-specific? How does BIRD expose route preference? |
| Anycast references | RFC 3258, DNS anycast operational articles, operator talks. | What makes anycast work? What failure modes should be tested in a small lab? |
| DNS operations | RFCs, DNS-OARC material, NSD/Knot/PowerDNS/Unbound docs. | How should authoritative and recursive roles be separated? How does reverse DNS work in DN42? |

### Citation Tracking

Use `research/sources.yml` as the source registry:

```yaml
- id: dn42-getting-started
  title: DN42 Getting Started
  url: https://dn42.cc/wiki/howto/getting-started/
  category: dn42
  reviewed_on: 2026-06-15
  status: research-required
  notes: "Use for registry object overview, not as unverified command truth."
```

Rules:

- Every chapter has a `References` section using source IDs.
- Every command block derived from current DN42 practice must point to a research note or source ID.
- Mark source-dependent claims as one of:
  - `conceptual`: stable networking principle.
  - `implementation`: tool behavior that can change by version.
  - `dn42-current`: current community practice; must be revalidated before release.
- Keep snapshots of volatile DN42 pages in `research/snapshots/` with date and source URL.
- Run link checks in CI.
- Review all `dn42-current` claims before each release.

### Local Reference Material Cache

The project should keep enough reference material locally to avoid repeatedly rediscovering sources, but it should not casually vendor entire websites.

Use three tiers:

1. **Tracked source registry:** `research/sources.yml`
   - Canonical URL, title, category, source authority, reviewed date, volatility, license notes, and chapters using it.
   - Always tracked in Git.

2. **Tracked research notes and small snapshots:** `research/notes/` and `research/snapshots/`
   - Human/agent-authored summaries, extracted facts, command provenance, and short quoted excerpts within license/fair-use limits.
   - Small text snapshots of volatile DN42 pages may be tracked when they are necessary to explain why a chapter made a decision.
   - Each snapshot must include URL, retrieval date, and license/usage note.

3. **Ignored raw cache:** `research/cache/`
   - Downloaded HTML, PDFs, WARC files, cloned docs repos, generated indexes, and other bulky or license-ambiguous material.
   - Ignored by default so local agents can work quickly without bloating the public repository.
   - Rebuild with scripts from `research/sources.yml`.

Rules:

- Track notes, metadata, and curated small snapshots.
- Ignore bulk raw downloads by default.
- Do not republish third-party docs wholesale unless their license clearly permits it and there is a project reason.
- Prefer canonical links plus local notes over copied pages.
- For DN42-current practice, keep retrieval dates visible in notes and refresh before release.
- For RFCs and official manuals, cite canonical URLs and cache local copies only for agent convenience.

## 4. Experiment Roadmap

### Foundation Labs

1. Build a local Linux namespace router.
2. Observe longest-prefix match.
3. Use `ip route get` to predict forwarding.
4. Add and remove blackhole routes.
5. Enable and disable forwarding.
6. Configure a safe firewall default.
7. Build a WireGuard tunnel between namespaces.
8. Run local BIRD between two lab routers.

### Pocket Internet Labs

1. Build the static Pocket Internet topology.
2. Add overlapping routes and observe longest-prefix match.
3. Break a selected link and repair static routes manually.
4. Add BIRD as a route manager.
5. Add BGP sessions between Pocket Internet routers.
6. Advertise loopback service prefixes.
7. Withdraw a prefix and observe convergence.
8. Change route preference and observe path selection.
9. Replace one veth link with WireGuard.
10. Explain which routing behavior changed and which routing behavior stayed the same.

### DN42 Interconnect Labs

1. Design a dedicated Pocket Internet/DN42 border router.
2. Separate lab links, WireGuard overlay links, and underlay Internet reachability.
3. Route selected Pocket Internet traffic toward DN42.
4. Prove the return path before expecting service reachability.
5. Add explicit import and export filters.
6. Verify that no default route or unauthorized prefix leaks across the border.
7. Roll back border changes and prove lab routing still works.

### First Real DN42 Labs

1. Register ASN, prefix, maintainer, person, route, and optional DNS objects.
2. Configure first DN42 WireGuard tunnel on the border.
3. Configure BIRD 2 with one DN42 peer.
4. Validate ROA-style filtering.
5. Install accepted routes into Linux kernel.
6. Debug kernel route installation.
7. Configure firewall safely.
8. Prevent accidental public Internet egress through DN42.
9. Configure split DNS for `.dn42`.
10. Reach first DN42 service from the Pocket Internet side where policy allows.

### Multi-Peer and Policy Labs

1. Add second peer.
2. Observe BGP route selection.
3. Break a peer and observe convergence.
4. Add route preference / local-pref policy.
5. Build export filters.
6. Build import filters.
7. Reject invalid origin routes.
8. Compare route visibility between BIRD and Linux.
9. Explore BGP communities.
10. Document failure modes.

### Service Labs

1. Run a DN42 web service.
2. Run a looking glass.
3. Run authoritative DNS.
4. Configure reverse DNS.
5. Monitor BGP sessions.
6. Build dashboards and alerts.
7. Capture command transcripts for reproducibility.

### Advanced Labs

1. Build anycast service.
2. Build two-region / multi-POP topology.
3. Simulate site failure.
4. Observe anycast convergence and sticky client behavior.
5. Tune local preference and AS-path prepending.
6. Evaluate when not to provide transit.
7. Publish an operational runbook.

## 5. Safety and Correctness

Safety is part of the curriculum, not an appendix.

### Recurring Warnings

- Do not leak public Internet routes into DN42.
- Do not leak DN42 or private routes to public interfaces.
- Do not accidentally announce prefixes you do not own.
- Do not provide public Internet egress through DN42 unless you intentionally operate and secure that service.
- Do not accept a default route from a DN42 peer during beginner labs.
- Do not export routes learned from one peer to another until the export policy is explicit and reviewed.
- Do not assume WireGuard `AllowedIPs` is only an ACL; it also affects routing behavior in common configurations.
- Do not ignore source address selection. A packet can leave through the right interface with the wrong source address and fail on the return path.
- Do not disable host firewalls globally to "make BGP work."
- Do not publish private keys, real home IPs, or personal contact data accidentally in examples.

### Verify Before Proceeding Checklist

Each lab should end with:

```text
Verify before proceeding:
- [ ] I can identify the underlay public interface and the DN42 overlay interface.
- [ ] `ip route get <dn42-target>` uses the expected DN42 route.
- [ ] `ip route get 1.1.1.1` does not use DN42.
- [ ] BIRD exports only my authorized prefixes.
- [ ] BIRD imports only routes accepted by current filters.
- [ ] No default route was learned from DN42 unless the lab explicitly requires it.
- [ ] Firewall rules allow required tunnel/BGP traffic and deny unintended forwarding.
- [ ] Rollback commands are written down and tested.
```

### Rollback Pattern

Every experiment should include:

- Stop service: `systemctl stop bird` or equivalent.
- Disable service from boot when needed.
- Bring tunnel down.
- Remove temporary route rules.
- Restore previous config from `experiments/backups/<lab-id>/`.
- Confirm public Internet path still uses normal default route.
- Confirm no DN42 routes remain if the lab is fully rolled back.

Use exact rollback commands per lab after research confirms the target distro and service manager.

## 6. Reader Learning Path

### After Part 1

The reader understands packets, interfaces, route lookup, connected routes, and forwarding.

You know it works when:

- They can explain why a ping takes a specific path.
- They can use `ip route get` before running `ping`.
- They can identify when a route is missing vs when a firewall blocks traffic.

You probably broke:

- Addressing, if connected routes are absent.
- Forwarding, if the router can ping both sides but hosts cannot ping through it.
- Firewall policy, if route lookup is correct but counters show drops.

### After Part 2

The reader has built a Pocket Internet with multiple routers, service loopbacks, and static routes.

You know it works when:

- They can explain forward path and return path separately.
- They can predict route lookup before sending packets.
- They can explain why a backup link is not useful until routing points to it.
- They can repair reachability by changing explicit static routes.

You probably broke:

- route tables, if `ip route get` says `Network is unreachable`,
- forwarding, if the next hop receives packets but does not pass them on,
- return path, if requests arrive but replies do not return.

### After Part 3

The reader can reason about dynamic routing inside Pocket Internet.

You know it works when:

- BIRD sessions exchange reachability.
- Loopback service prefixes are advertised and withdrawn.
- Kernel routes appear because the routing daemon selected them.
- A failed link or withdrawn prefix causes observable convergence.

You probably broke:

- neighbor configuration, if BGP never establishes,
- export policy, if service prefixes never leave their source router,
- next-hop reachability, if BIRD selects a route Linux cannot install.

### After Part 4

The reader understands that a WireGuard tunnel can replace a local lab link without changing the larger routing model.

You know it works when:

- WireGuard has a current handshake.
- The same prefixes remain reachable through the tunnel link.
- The reader can identify underlay traffic and overlay traffic.
- MTU and keepalive behavior are visible rather than mysterious.

### After Part 5

The reader can explain how Pocket Internet approaches DN42 through a controlled border.

You know it works when:

- no Pocket Internet route is exported toward DN42 by default,
- outbound reachability is treated as an explicit design question,
- no default route is accidentally accepted or exported,
- authorized prefixes are explicit,
- filters prevent route leaks,
- rollback removes border changes without damaging the local lab.

### After Part 6

The reader can operate services across the lab/real-network boundary.

You know it works when:

- DN42 services are reachable from inside Pocket Internet where routing and policy allow,
- selected Pocket Internet services are exposed only after authorization and filtering checks,
- DNS, monitoring, firewall policy, and rollback are part of the service design,
- service failures can be explained as forward-path, return-path, policy, firewall, or application failures.

## 7. Authoring Workflow

### Git Workflow

- `main`: published, reviewed content.
- `draft/<chapter-slug>`: chapter drafts.
- `lab/<experiment-slug>`: experiment development.
- `research/<topic>`: source review and notes.
- Pull requests must include:
  - chapter or experiment ID,
  - tested environment,
  - source list,
  - screenshots or transcripts for nontrivial labs,
  - safety checklist status.

### Issue Labels

- `chapter`
- `experiment`
- `research`
- `dn42-current`
- `conceptual`
- `tooling`
- `safety`
- `needs-lab-test`
- `needs-source-review`
- `broken-link`
- `v0.1`
- `github-pages`
- `reference-cache`
- `source-refresh`
- `good-first-lab`

### Milestones

- `v0.1`: zero to one safe working peer, split DNS, first service access.
- `v0.2`: second peer, route selection, convergence, import/export policy.
- `v0.3`: services, looking glass, DNS operations, monitoring.
- `v0.4`: anycast, multi-POP, traffic engineering, BGP communities.

### Suggested Initial GitHub Issues

1. Scaffold MkDocs Material with `uv`.
2. Add GitHub Pages deployment workflow.
3. Add strict build and link-check workflow.
4. Create source registry validation script.
5. Review DN42 registry README and schema.
6. Review current DN42 BIRD 2 examples.
7. Review current DN42 WireGuard examples.
8. Build local namespace routing lab.
9. Build Pocket Internet static routing topology.
10. Add BIRD and BGP to Pocket Internet.
11. Replace one Pocket Internet link with WireGuard.
12. Draft addresses, prefixes, and longest match.
13. Design the Pocket Internet to DN42 border.
14. Draft safety page.
15. Draft registry objects chapter.
16. Draft first WireGuard peer chapter.
17. Draft first BIRD session chapter.
18. Draft split DNS chapter.

### Chapter Template

```markdown
---
title: "Chapter Title"
status: draft
claim_types:
  - conceptual
  - implementation
  - dn42-current
tested_on:
  distro: "research required"
  kernel: "research required"
  bird: "research required"
  wireguard_tools: "research required"
---

# Chapter Title

## Concept

Explain the stable networking idea in plain language.

## Why It Matters

Explain what breaks if the reader does not understand this.

## Lab / Experiment

### Goal

State the observable outcome.

### Setup

List assumptions and required packages.

### Steps

Use commands only after they have been tested or clearly marked as research required.

## Expected Observations

Describe what the reader should see and why.

## Troubleshooting Notes

Use branches:

- If you see X, check Y.
- If command A succeeds but command B fails, suspect Z.

## How the Real Internet Does This

Compare the lab to public Internet practice without pretending DN42 is identical.

## Verify Before Proceeding

- [ ] Route lookup matches the expected interface.
- [ ] No unintended default route exists.
- [ ] Export policy is explicit.

## Rollback

List exact rollback commands.

## References

- source-id: short reason used
```

### Experiment Template

```markdown
---
experiment_id: exp-first-bird-session
status: draft
risk: medium
requires_public_dn42_peer: true
tested: false
---

# Experiment: First BIRD Session

## Question

Can this router establish one BGP session over WireGuard and import DN42 routes without exporting anything unintended?

## Hypothesis

If WireGuard is up, BIRD has the correct neighbor address and ASN, and TCP/179 is allowed, the session should reach Established.

## Safety Boundaries

- No default route accepted.
- Export only owned prefixes.
- Reject invalid origin routes.
- Keep a rollback copy of BIRD config.

## Procedure

1. Confirm WireGuard handshake.
2. Start BIRD with peer disabled.
3. Validate config.
4. Enable peer.
5. Inspect BIRD protocol state.
6. Inspect imported routes.
7. Inspect kernel routes.

## Expected Observations

- `birdc show protocols` shows the peer Established.
- `birdc show route` shows accepted routes.
- `ip route` shows only routes exported to kernel.

## Troubleshooting Branches

- No WireGuard handshake: check endpoint, keys, NAT, firewall.
- BGP Active: check neighbor address and TCP/179.
- Established but no routes: check import filter and ROA table.
- Routes in BIRD but not kernel: check kernel protocol and next-hop reachability.

## Rollback

1. Disable peer in BIRD config.
2. Reload BIRD.
3. Bring down WireGuard interface if needed.
4. Confirm no unexpected DN42 routes remain in kernel.

## Evidence to Capture

- `wg show`
- `birdc show protocols all`
- `birdc show route count`
- `ip route get <dn42-service>`
- `ip route get 1.1.1.1`

## References

- dn42-getting-started
- bird-docs
- wireguard-quickstart
```

### Research Note Template

```markdown
---
source_id: dn42-bird2
url: "research required"
reviewed_on: YYYY-MM-DD
reviewer: codex
status: draft
claim_type: dn42-current
---

# Source Review: DN42 BIRD 2

## What This Source Is Authoritative For

## What This Source Is Not Authoritative For

## Claims We Can Use

## Claims Requiring Confirmation

## Commands or Config Derived From This Source

## Links to Chapters
```

### Diagram Strategy

- Use Mermaid for simple packet paths, route selection flow, and state machines.
- Use generated SVG/PNG diagrams only where topology readability matters.
- Store source diagrams in `diagrams/source/`.
- Store generated outputs in `diagrams/generated/`.
- Every topology diagram should name:
  - ASNs,
  - prefixes,
  - tunnel interfaces,
  - underlay endpoints,
  - routing policy boundaries.

### Command Testing

- Commands in conceptual local labs must be tested in disposable namespaces or containers.
- Commands that require public DN42 state must be marked `dn42-current` and tested before release.
- Store command transcripts in `experiments/transcripts/<lab-id>/`.
- Do not publish commands copied from the wiki without local validation or a research-required marker.

### Separating Current Practice From Principles

Use visible callouts:

- **Principle:** stable networking concept.
- **Linux behavior:** implementation-specific to Linux and tool versions.
- **DN42 current practice:** community/registry practice that must be checked before release.
- **Lab simplification:** intentionally simplified model.

## 8. Automation and Tooling Ideas

### Initial Tooling

- `uv run mkdocs serve`: local preview.
- `uv run mkdocs build --strict`: fail on navigation and Markdown problems.
- Markdown linting with a configured linter.
- Link checking with an allowlist for DN42 internal names.
- YAML validation for `research/sources.yml`.
- Mermaid diagram validation.

### Example Validation

- Parse Markdown code blocks with labels:
  - `console`
  - `bird`
  - `nft`
  - `systemd-networkd`
  - `resolved`
- Require each command block to include:
  - lab ID,
  - tested status,
  - expected exit behavior,
  - rollback reference.
- Validate that dangerous commands are tagged with safety notes.

### Transcript Capture

Provide `scripts/capture_transcript.py` to run safe local namespace labs and save:

- command,
- exit code,
- stdout,
- stderr,
- timestamp,
- environment metadata.

### Optional Lab Automation

Future options:

- Containerlab topology for repeatable multi-router labs.
- Linux network namespace scripts for no-cloud first-principles labs.
- Vagrant/libvirt for closer-to-router VM labs.
- Ansible only after manual labs are clear; automation should not hide the learning.

### Future Codex/Agent Integration

Use agents for:

- source freshness checks,
- broken link triage,
- command transcript comparison,
- chapter draft review against templates,
- safety checklist enforcement,
- generating glossary entries from accepted chapters.

Agents should not silently update command examples from volatile DN42 sources. They should open a research PR that shows the source diff and affected chapters.

## 9. First Milestone: v0.1

### v0.1 Scope

Goal: build the Pocket Internet foundation and prepare a safe DN42 border model before the first real peer.

Included:

- Site scaffold with MkDocs Material.
- Safety page.
- Glossary starter.
- Part 1 core chapters:
  - Linux as a Router.
  - Addresses and Prefixes.
  - Routing Tables.
  - Pocket Internet with Static Routes.
- Pocket Internet foundation chapters:
  - Addresses, Prefixes, and Longest Match.
  - Route selection and static route repair.
  - BIRD and BGP inside Pocket Internet.
  - WireGuard as a replacement for one lab link.
- Interconnect design:
  - Pocket Internet to DN42 border.
  - Outbound reachability.
  - Return path.
  - Import/export filtering.
  - Rollback and route-leak checks.
- Research source registry.
- Chapter and experiment templates.
- One tested local namespace lab.

Excluded from v0.1:

- Real DN42 registry submission.
- Public DN42 peering.
- Publicly reachable Pocket Internet services.
- Anycast.
- Multi-POP.
- Looking glass.
- Dashboards.
- BGP communities deep dive.
- Full DNS operations.
- Automated DN42 registration.

### Concrete v0.1 Task List

1. Create MkDocs Material scaffold with `uv`.
2. Add GitHub Pages deployment workflow.
3. Add `mkdocs.yml` navigation matching the v0.1 scope.
4. Add `docs/safety.md`.
5. Add `docs/glossary.md`.
6. Add chapter and experiment templates.
7. Create `research/sources.yml` with initial source IDs.
8. Add reference-cache policy and `.gitignore` rules.
9. Create initial GitHub issue labels and `v0.1` milestone.
10. Review DN42 registry README and schema docs.
11. Review current DN42 BIRD 2 and WireGuard pages.
12. Write and test local namespace routing lab.
13. Draft addresses, prefixes, and longest match.
14. Write and test Pocket Internet static routing lab.
15. Write and test Pocket Internet route-selection lab.
16. Write and test local BIRD/BGP lab.
17. Replace one Pocket Internet link with WireGuard.
18. Design the Pocket Internet to DN42 border.
19. Add link checker and strict docs build CI.
20. Run a source freshness review before tagging v0.1.
21. Tag `v0.1.0` only after all published command blocks are either tested or clearly marked research-required.

## 10. Immediate Next Tasks

1. Finish the Pocket Internet rename and reframe.
2. Draft `Addresses, Prefixes, and Longest Match`.
3. Build the route-selection and longest-prefix lab.
4. Add BIRD and BGP to Pocket Internet.
5. Replace one Pocket Internet link with WireGuard.
6. Design the Pocket Internet to DN42 border.
7. Then implement real DN42 registry and peer chapters.

## Initial Source List

- [mdBook documentation](https://rust-lang.github.io/mdBook/)
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [MkDocs deployment documentation](https://www.mkdocs.org/user-guide/deploying-your-docs/)
- [Docusaurus deployment documentation](https://docusaurus.io/docs/deployment)
- [GitBook documentation](https://gitbook.com/docs/)
- [DN42 getting started](https://dn42.cc/wiki/howto/getting-started/)
- [BIRD Internet Routing Daemon](https://bird.network.cz/)
- [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
- [Linux ip-route(8)](https://man7.org/linux/man-pages/man8/ip-route.8.html)
- [RFC 4271: BGP-4](https://www.rfc-editor.org/rfc/rfc4271)
- [RFC 6811: BGP Prefix Origin Validation](https://www.rfc-editor.org/rfc/rfc6811)
- [RFC 4193: Unique Local IPv6 Unicast Addresses](https://www.rfc-editor.org/rfc/rfc4193)
- [RFC 3258: Shared Unicast Authoritative DNS](https://www.rfc-editor.org/rfc/rfc3258)
- [RIPE NCC RPKI ROA Management](https://www.ripe.net/manage-ips-and-asns/resource-management/rpki/resource-certification-roa-management/)
