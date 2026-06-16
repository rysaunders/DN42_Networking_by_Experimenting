# Addresses, Prefixes, and Longest Match

## Reader Starting Point

This chapter assumes you have completed Linux as a Router. You should know what an address, interface, prefix, route, next hop, and route lookup are.

You do not need to know binary subnet math yet. This chapter uses route lookups to build the idea from observable behavior first.

The goal is to answer one question:

> When more than one route could match a destination, which one does Linux choose?

## New Terms

| Term | Plain-language meaning | Example |
| --- | --- | --- |
| Address | One specific point in the IP address space. | `172.20.30.42` |
| Prefix | A set of addresses written as a starting address plus a length. | `172.20.0.0/16` |
| Prefix length | The number after `/`. A larger number means a smaller, more specific set. | `/24` is more specific than `/16`. |
| Host route | A route for exactly one IP address. | `172.20.30.42/32` |
| Default route | The fallback route when nothing more specific matches. | `default via 10.0.0.2` |
| Longest-prefix match | The rule that the most specific matching route wins. | `/32` wins over `/24`, `/16`, and default. |

## Mental Model

Think of prefixes as nested containers:

```text
default route
└── 172.20.0.0/16
    └── 172.20.30.0/24
        └── 172.20.30.42/32
```

The destination `172.20.30.42` is inside all four containers. Linux chooses the smallest matching container because it is the most specific instruction.

That is longest-prefix match.

## Why It Matters

Pocket Internet will quickly have more than one possible path. Later, BIRD and BGP will install routes automatically, but the Linux kernel still forwards packets by looking up the destination address in a route table.

If you cannot predict route lookup, later BGP behavior will feel like magic. If you can predict route lookup, BGP becomes easier to understand: it is a way for routers to learn and install routes.

## Address Versus Prefix

An address names one point:

```text
172.20.30.42
```

A prefix names a set of points:

```text
172.20.30.0/24
```

For now, read `/24` as "a group that includes addresses from `172.20.30.0` through `172.20.30.255`."

Read `/32` as "only this one IPv4 address."

| Prefix | Plain-language set |
| --- | --- |
| `172.20.0.0/16` | Anything that starts with `172.20.` |
| `172.20.30.0/24` | Anything that starts with `172.20.30.` |
| `172.20.30.42/32` | Only `172.20.30.42` |
| `10.0.0.0/30` | A tiny link-sized prefix used by two interface addresses in this lab. |

The larger prefix length is more specific:

```text
/32 is more specific than /24
/24 is more specific than /16
/16 is more specific than default
```

The `/30` routes in this lab are not the main lesson. They create small connected prefixes for the fake next-hop addresses. You do not need the full address math yet; notice only that assigning `10.0.0.1/30` to `broad0` creates a connected route for `10.0.0.0/30`.

## Lab

The validated lab script lives at:

```text
experiments/labs/addresses-longest-match/run.sh
```

The transcript used for this chapter is:

```text
experiments/transcripts/addresses-longest-match-20260616T124649Z.txt
```

Run it from the repository root on Linux or inside the OrbStack Linux machine:

```sh
bash experiments/labs/addresses-longest-match/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/addresses-longest-match/run.sh
```

These commands must run with root privileges inside the Linux environment because network namespaces, interfaces, and routes are system-level objects. The script uses `sudo` when it is not already running as root.

## What the Script Builds

The script creates one temporary namespace:

```text
addrmatch
```

Inside it, the script creates three dummy interfaces. A dummy interface is a local-only interface that is useful for route lookup experiments because no real packet needs to leave the machine.

This lab tests route selection, not packet delivery. The next-hop addresses are placeholders inside each connected `/30`. We are asking Linux which route it would choose; we are not proving that a packet reaches a real neighbor. The next Pocket Internet lab uses real veth peers, so delivery and replies become visible there.

| Interface | Connected prefix | Meaning in this lab |
| --- | --- | --- |
| `broad0` | `10.0.0.0/30` | path for broad routes |
| `specific0` | `10.0.1.0/30` | path for more-specific routes |
| `host0` | `10.0.2.0/30` | path for one exact host route |

Then the script installs overlapping routes:

```text
default via 10.0.0.2 dev broad0
172.20.0.0/16 via 10.0.0.2 dev broad0
172.20.30.0/24 via 10.0.1.2 dev specific0
172.20.30.42/32 via 10.0.2.2 dev host0
```

These routes are intentionally artificial. They create a clean route table where the only thing changing is prefix specificity.

## Read One Route

Take this route:

```text
172.20.30.0/24 via 10.0.1.2 dev specific0
```

Read it as:

> For destinations inside `172.20.30.0/24`, send packets to next hop `10.0.1.2` through interface `specific0`.

That one route has three parts:

| Route part | Meaning |
| --- | --- |
| `172.20.30.0/24` | The destination prefix this route matches. |
| `via 10.0.1.2` | The next hop Linux would send the packet to. |
| `dev specific0` | The interface Linux would send the packet through. |

Longest-prefix match is about the destination prefix part. After Linux chooses the winning route, the `via` and `dev` parts tell it where the packet would go next.

## Predict Before Revealing

Work in two passes. First decide which prefixes match each destination.

| Destination | Does `/16` match? | Does `/24` match? | Does `/32` match? |
| --- | --- | --- | --- |
| `172.20.30.42` | ? | ? | ? |
| `172.20.30.99` | ? | ? | ? |
| `172.20.99.5` | ? | ? | ? |
| `203.0.113.10` | ? | ? | ? |

??? question "Reveal the matching prefixes"

    | Destination | Matching routes |
    | --- | --- |
    | `172.20.30.42` | default, `/16`, `/24`, `/32` |
    | `172.20.30.99` | default, `/16`, `/24` |
    | `172.20.99.5` | default, `/16` |
    | `203.0.113.10` | default |

Now decide which interface wins. Remember: the longest matching prefix wins.

| Destination | Winning interface |
| --- | --- |
| `172.20.30.42` | ? |
| `172.20.30.99` | ? |
| `172.20.99.5` | ? |
| `203.0.113.10` | ? |

??? question "Reveal the expected interfaces"

    | Destination | Expected interface | Why |
    | --- | --- | --- |
    | `172.20.30.42` | `host0` | `/32` is the longest matching prefix. |
    | `172.20.30.99` | `specific0` | `/24` is longer than `/16` and default. |
    | `172.20.99.5` | `broad0` | `/16` matches, but `/24` and `/32` do not. |
    | `203.0.113.10` | `broad0` | Only the default route matches. |

## Observe Route Lookup

The transcript confirms the predictions:

```sh
ip -n addrmatch route get 172.20.30.42
```

```text
172.20.30.42 via 10.0.2.2 dev host0 src 10.0.2.1
```

The `/32` host route wins.

```sh
ip -n addrmatch route get 172.20.30.99
```

```text
172.20.30.99 via 10.0.1.2 dev specific0 src 10.0.1.1
```

The `/24` route wins because it is the longest matching prefix for that destination.

```sh
ip -n addrmatch route get 172.20.99.5
```

```text
172.20.99.5 via 10.0.0.2 dev broad0 src 10.0.0.1
```

The `/16` route wins because the destination starts with `172.20.` but not with `172.20.30.`.

```sh
ip -n addrmatch route get 203.0.113.10
```

```text
203.0.113.10 via 10.0.0.2 dev broad0 src 10.0.0.1
```

The default route wins because no more-specific route matches.

## Remove a More-Specific Route

The script removes the `/32` route:

```sh
ip -n addrmatch route delete 172.20.30.42/32
```

Now ask the same question again:

```sh
ip -n addrmatch route get 172.20.30.42
```

```text
172.20.30.42 via 10.0.1.2 dev specific0 src 10.0.1.1
```

The destination did not change. The route table changed. Without the `/32`, the `/24` is now the longest matching prefix.

Then the script removes the `/24`:

```sh
ip -n addrmatch route delete 172.20.30.0/24
```

The same destination falls back again:

```text
172.20.30.42 via 10.0.0.2 dev broad0 src 10.0.0.1
```

This is the core rule:

> Linux does not choose the first matching route. It chooses the longest matching route.

## Source Address Note

The route lookup output includes a `src` value:

```text
src 10.0.1.1
```

That is the source address Linux would prefer for a packet using that route. Source address selection is related to route lookup, but it is not the same decision.

For now, keep the simple version:

- destination address decides which route matches,
- selected route influences which source address Linux chooses,
- return traffic only works if the other side has a route back to that source.

Later Pocket Internet chapters will make the return path visible.

## Connection to Pocket Internet

The next Pocket Internet lab uses service loopbacks like:

```text
172.20.1.1/32
172.20.3.1/32
```

Those `/32` addresses are exact service destinations. When a router has both a broad route and a more-specific service route, the more-specific route wins.

That is why prefix length matters before BGP appears. BGP will eventually exchange prefixes, but the forwarding rule stays the same: the most-specific installed route wins.

Here is the same idea in Pocket Internet terms:

```text
172.20.0.0/16 via transit
172.20.3.1/32 via pocket-as3
```

Traffic to `172.20.3.1` follows the `/32` service route because it is more specific. Traffic to `172.20.9.9` follows the broader `/16` route because the `/32` does not match.

Specific service routes override broader reachability. That is the route-selection habit this chapter is building before the topology gets larger.

## Verify Before Proceeding

- [ ] You can explain the difference between one address and a prefix.
- [ ] You can explain why `/32` is more specific than `/24`.
- [ ] You can predict which route wins when several routes match.
- [ ] You can use `ip route get` to check Linux's selected route.
- [ ] You can explain why removing a more-specific route changes the selected path.

## References

- `linux-ip-route`: use this for exact Linux route syntax and route lookup behavior.
- `rfc-4193`: use this later for IPv6 unique local address background.
- Transcript: `experiments/transcripts/addresses-longest-match-20260616T124649Z.txt`.
