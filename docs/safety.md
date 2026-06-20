# Safety

Safety is part of the curriculum. These labs change real Linux network state, even when the topology is local and disposable.

The rule is simple:

> Know what boundary the lab is allowed to cross, know what could leak, and know how to roll back before you make the change.

## Lab Safety Levels

Use the smallest safety level that matches the lab.

| Level | Lab shape | Main risk | Required proof |
| --- | --- | --- | --- |
| Local namespace lab | Only temporary namespaces, veth pairs, dummy interfaces, and local routes. | Leftover namespaces or routes confuse later labs. | Cleanup leaves no lab namespaces. |
| Routing-daemon lab | BIRD or another routing program installs routes inside the lab. | A learned route is installed somewhere unexpected. | Kernel route table contains only expected lab routes. |
| WireGuard lab | A lab link becomes an overlay tunnel. | Tunnel configuration captures traffic it should not carry. | Public default route still uses the normal interface. |
| DN42 interconnect lab | Pocket Internet touches a real DN42 peer or route table. | Default-route mistakes, route leaks, unauthorized export, or public egress. | Import, export, route, firewall, and rollback checks all pass. |

Most early Pocket Internet labs are level 1. BIRD/BGP inside Pocket Internet is level 2. Replacing a lab link with WireGuard is level 3. DN42 peering and interconnect work is level 4.

## Prominent Rules

These rules apply unless a chapter explicitly says otherwise and proves why the exception is safe.

- Do not install a default route into DN42.
- Do not accept a default route from a DN42 peer in beginner labs.
- Do not export any route until the export filter is explicit and reviewed.
- Do not announce prefixes you do not own or are not authorized to announce.
- Treat Pocket Internet prefixes and AS labels as lab-only unless a DN42 chapter explicitly replaces them with authorized resources.
- Do not leak public Internet routes into DN42.
- Do not leak DN42 or lab-only routes to public interfaces.
- Do not provide public Internet egress through DN42 unless that is the deliberate, secured service being built.
- Do not disable host firewalls globally to make a lab pass.
- Do not publish private keys, home IP addresses, or personal contact data by accident.

## Before A Lab

Capture the baseline before changing state.

For local namespace labs:

```sh
ip netns list
ip route
```

For WireGuard, BIRD, or DN42-facing labs, also capture:

```sh
ip route get 1.1.1.1
ip link show
```

If BIRD is involved:

```sh
birdc show protocols
birdc show route
```

If WireGuard is involved:

```sh
wg show
```

Do not treat these commands as magic incantations. The point is to know what normal looked like before the lab changed anything.

## During A Lab

After each major state change, ask:

- What object changed: namespace, interface, address, route, daemon state, firewall rule, or service?
- Did the change stay inside the intended boundary?
- Did a route appear in the kernel?
- Did a route appear in BIRD but not the kernel?
- Did a packet leave through the expected interface?
- Is there a return path?

Use route lookup before packet tests:

```sh
ip route get <destination>
```

Inside a namespace:

```sh
ip -n <namespace> route get <destination>
```

For DN42-facing labs, also check public Internet routing stays public:

```sh
ip route get 1.1.1.1
```

That command must not unexpectedly use a DN42 tunnel, WireGuard peer, or lab-only interface.

## Export Policy Checks

Export policy is where a lab can become a route leak.

Pocket Internet routes are not exported toward DN42 by default. Before any DN42-facing chapter changes that default, it must identify the authorized prefix being used and the filter that rejects everything else.

Before any route is advertised to another router, write down:

- the exact prefix being exported,
- why that prefix is authorized,
- the neighbor receiving it,
- the export filter that permits it,
- the default reject rule that blocks everything else,
- the command that proves what will be exported,
- the rollback command that stops the export.

For beginner labs, the safest export policy is:

```text
permit only the one expected lab prefix
reject everything else
```

Never use a permissive example as a temporary shortcut in a real DN42-facing chapter.

## DN42 Border Checklist

The Pocket Internet to DN42 border checklist is mandatory for later DN42-facing chapters. See [Pocket Internet to DN42 Border](pocket-internet-dn42-interconnect.md#mandatory-border-checklist).

Before a chapter touches a real DN42 peer, tunnel, route table, resolver path, or exposed service, it must show:

- no default route into DN42,
- no Pocket Internet lab prefix export,
- the exact authorized prefix or address being used,
- import policy that is default-deny or constrained-accept,
- export policy that is default-deny,
- route export dry-run or export inspection before relying on the route,
- rollback commands that stop the export, session, tunnel, route, resolver change, or service exposure,
- public Internet route sanity checks before and after the change.

The minimum public-route sanity check is:

```sh
ip route get 1.1.1.1
```

That route must not unexpectedly use DN42, a lab tunnel, or a Pocket Internet interface.

For BIRD-based DN42 chapters, the route export inspection should use the equivalent of:

```sh
birdc show route export <dn42_bgp_protocol_name>
```

The exact protocol name and expected output belong in the chapter. The important rule is that export is inspected before it is trusted.

Rollback must be equally concrete. A BIRD chapter might disable the peer protocol while a WireGuard chapter might remove or bring down the tunnel. The published chapter must show the exact rollback for the state it changes.

## Reusable Verification Checklist

Use the parts that match the lab.

- [ ] I can name the lab boundary: local namespace, routing daemon, WireGuard tunnel, or DN42 interconnect.
- [ ] I captured baseline routes and interfaces before the lab.
- [ ] Temporary namespaces use lab-specific names and are removed by rollback.
- [ ] `ip route get <target>` or `ip -n <namespace> route get <target>` uses the expected route.
- [ ] Forward path and return path are both explained.
- [ ] No unintended default route exists.
- [ ] `ip route get 1.1.1.1` still uses normal public Internet routing when the lab touches WireGuard or DN42.
- [ ] DN42-facing chapters satisfy the mandatory border checklist.
- [ ] BIRD imports only routes accepted by the current filter.
- [ ] BIRD exports only expected and authorized prefixes.
- [ ] Firewall rules allow required lab traffic without opening unrelated forwarding.
- [ ] Rollback commands are written down and tested.

## Rollback Pattern

Each lab should provide exact rollback commands. The general shape is:

1. Stop traffic generation or service checks.
2. Stop daemons started by the lab.
3. Remove BIRD protocols, filters, or temporary configuration added by the lab.
4. Remove temporary routes and route rules.
5. Bring down temporary WireGuard or tunnel interfaces.
6. Delete temporary namespaces, veth pairs, dummy interfaces, and generated files.
7. Restore configuration from backup if the lab edited persistent files.
8. Confirm no lab namespaces remain.
9. Confirm normal public Internet routing still uses the normal default route.
10. Confirm no unintended DN42 or lab-only routes remain in the kernel.

For namespace-only labs, rollback may be as small as:

```sh
ip netns delete <namespace>
```

For multi-namespace labs, delete every lab namespace and then verify:

```sh
if ip netns list | grep -E '<lab-prefix>'; then
  echo 'leftover lab namespaces found'
  exit 1
fi
echo 'no lab namespaces remain'
```

The check should fail if any matching namespace remains. A rollback proof should not hide leftover state.

## What Could Leak?

Every WireGuard, BIRD, or interconnect chapter should answer this before the lab starts:

- Could a default route move into the tunnel?
- Could a lab prefix be announced outside the lab?
- Could a public route be announced into DN42?
- Could a DN42 route be exported to the public side?
- Could a firewall change expose a service beyond the intended network?
- Could a private key, endpoint address, or personal contact detail be committed?

If the answer is yes, the chapter needs an explicit filter, firewall rule, or rollback check before the command appears.

## Chapter Requirement

A lab is not complete until it includes:

- its safety level,
- its boundary,
- the state it changes,
- the exact rollback commands,
- the verification commands that prove rollback worked.
