# Addresses, Prefixes, and Longest Match

## Reader Starting Point

This chapter assumes you have completed Linux as a Router. You should know what an address, interface, prefix, route, next hop, and route lookup are.

The previous lab showed that packets only move when route tables say where they should go. This chapter slows down on one part of that idea: how Linux chooses a route when several route entries could match the same destination.

Treat this chapter like a microscope. The lab is intentionally small and artificial so only one thing is changing: the specificity of the destination prefix. You will not prove packet delivery here. You will learn the route-lookup rule that later Pocket Internet routers will use.

If you need the bigger map while working through the small lab, use [Linux Networking Objects](../linux-networking-objects.md).

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

Here, `default` means the default route: the fallback route Linux uses when no more-specific route matches.

The `/30` routes in this lab are not the main lesson. They create small connected prefixes for the fake next-hop addresses. You do not need the full address math yet; notice only that assigning `10.0.0.1/30` to `broad0` creates a connected route for `10.0.0.0/30`.

## Connected Routes and Local Neighborhoods

A connected route is Linux saying:

> I have an interface inside this prefix, so addresses in this prefix are on my local link.

In a normal home or office network, this might look like:

```text
laptop:  192.168.1.23/24
printer: 192.168.1.80
router:  192.168.1.1
```

When the laptop has `192.168.1.23/24` on its Wi-Fi interface, Linux creates a connected route like:

```text
192.168.1.0/24 dev wlan0
```

Read that as:

> Destinations inside `192.168.1.0/24` are reachable directly through `wlan0`.

The laptop does not send printer traffic to the router first. Because `192.168.1.80` is inside the connected route, Linux treats the printer as local to that LAN. The packet still has to cross the Wi-Fi or switch, but it does not need an IP router hop.

Traffic to something outside that local neighborhood, like `8.8.8.8`, needs a different route:

```text
default via 192.168.1.1 dev wlan0
```

That means:

> If nothing more specific matches, send the packet to the router at `192.168.1.1`.

This is the mental model for the lab:

- `10.0.1.1/30 dev specific0` gives `specific0` one address.
- The `/30` makes Linux create `10.0.1.0/30 dev specific0`.
- Because `10.0.1.2` is inside that connected route, Linux accepts it as a plausible next hop.

The dummy interface is not a real Wi-Fi network or switch. It is a controlled way to make Linux believe a tiny local neighborhood exists so we can study route selection.

## Lab

Build this lab by typing the commands yourself. The repeated typing is part of the lesson: routes become easier to reason about when you have created the namespace, interfaces, addresses, and route entries by hand.

These commands must run with root privileges inside the Linux environment because network namespaces, interfaces, and routes are system-level objects. On macOS, use an OrbStack shell:

```sh
orb
```

Then run the commands from that Linux shell as root, or prefix them with `sudo`.

## What You Will Build

You will create one temporary namespace:

```text
addrmatch
```

Inside it, you will create three dummy interfaces. A dummy interface is a local-only interface that is useful for route lookup experiments because no real packet needs to leave the machine.

This lab tests route selection, not packet delivery. The next-hop addresses are placeholders inside each connected `/30`. We are asking Linux which route it would choose; we are not proving that a packet reaches a real neighbor.

That is the boundary of this chapter:

- one namespace,
- fake local exits,
- no neighbor namespaces,
- no ping test,
- no return path.

The next Pocket Internet lab uses real veth peers, so delivery and replies become visible there. The Pocket Internet route-selection lab later reuses this same lookup rule inside a router role, where each winning route points toward a different exit.

| Interface | Connected prefix | Meaning in this lab |
| --- | --- | --- |
| `broad0` | `10.0.0.0/30` | path for broad routes |
| `specific0` | `10.0.1.0/30` | path for more-specific routes |
| `host0` | `10.0.2.0/30` | path for one exact host route |

Then you will install overlapping routes:

```text
default via 10.0.0.2 dev broad0
172.20.0.0/16 via 10.0.0.2 dev broad0
172.20.30.0/24 via 10.0.1.2 dev specific0
172.20.30.42/32 via 10.0.2.2 dev host0
```

These routes are intentionally artificial. They create a clean route table where the only thing changing is prefix specificity.

## Step 1: Clean Up Any Old Lab State

If you ran this lab before, delete the old namespace first:

```sh
ip netns delete addrmatch 2>/dev/null || true
```

Confirm it is gone:

```sh
ip netns list | grep -E '^addrmatch( |$)' || true
```

No output is the expected result.

## Step 2: Create One Namespace

Create the namespace:

```sh
ip netns add addrmatch
```

Check that Linux sees it:

```sh
ip netns list
```

Expected output includes:

```text
addrmatch
```

At this point, you have one isolated network stack. It has its own interfaces and route table.

## Step 3: Add Local-Only Interfaces

Create three dummy interfaces inside the namespace:

```sh
ip -n addrmatch link add broad0 type dummy
ip -n addrmatch link add specific0 type dummy
ip -n addrmatch link add host0 type dummy
```

These names are deliberately plain:

- `broad0` is the broad/default exit,
- `specific0` is the more-specific exit,
- `host0` is the exact-host exit.

These are labels for route selection. They are not real routers.

## Step 4: Add Addresses

Assign one address-with-prefix to each dummy interface:

```sh
ip -n addrmatch addr add 10.0.0.1/30 dev broad0
ip -n addrmatch addr add 10.0.1.1/30 dev specific0
ip -n addrmatch addr add 10.0.2.1/30 dev host0
```

This syntax can look odd at first. `10.0.0.1/30` does two related things:

- `10.0.0.1` is the specific address assigned to `broad0`,
- `/30` tells Linux the size of the local connected prefix around that address.

So the interface does have one specific address: `10.0.0.1`. The `/30` does not mean "assign every address in the `/30` to this interface." It means "this address lives on a local link whose prefix is `/30`."

Linux uses that prefix length to create a connected route. For example, assigning `10.0.0.1/30` to `broad0` creates a connected route for `10.0.0.0/30`.

That connected route is what makes `10.0.0.2` look local to `broad0`. Linux will allow a route such as `default via 10.0.0.2 dev broad0` only if the next hop looks reachable through `broad0`.

If you assigned `10.0.0.1/32` instead, Linux would treat only `10.0.0.1` as directly connected. That is useful for loopback service addresses, but it would not describe a small local link with a next-hop address like `10.0.0.2`.

## Step 5: Bring Interfaces Up

Bring up loopback and the three dummy interfaces:

```sh
ip -n addrmatch link set lo up
ip -n addrmatch link set broad0 up
ip -n addrmatch link set specific0 up
ip -n addrmatch link set host0 up
```

Now inspect the connected routes Linux created automatically:

```sh
ip -n addrmatch route
```

Expected output:

```text
10.0.0.0/30 dev broad0 proto kernel scope link src 10.0.0.1
10.0.1.0/30 dev specific0 proto kernel scope link src 10.0.1.1
10.0.2.0/30 dev host0 proto kernel scope link src 10.0.2.1
```

Those routes exist because the interface addresses exist. You did not add them by hand.

## Step 6: Add Overlapping Routes

Now add the routes that will compete with each other:

```sh
ip -n addrmatch route add default via 10.0.0.2 dev broad0
ip -n addrmatch route add 172.20.0.0/16 via 10.0.0.2 dev broad0
ip -n addrmatch route add 172.20.30.0/24 via 10.0.1.2 dev specific0
ip -n addrmatch route add 172.20.30.42/32 via 10.0.2.2 dev host0
```

Show the route table:

```sh
ip -n addrmatch route
```

Expected output includes:

```text
default via 10.0.0.2 dev broad0
172.20.0.0/16 via 10.0.0.2 dev broad0
172.20.30.0/24 via 10.0.1.2 dev specific0
172.20.30.42 via 10.0.2.2 dev host0
```

Linux may display `172.20.30.42/32` as `172.20.30.42`. Those mean the same thing: an exact host route.

Keep this route table visible while you work through the prediction exercise. You do not need to do subnet math in your head. The point is to compare the destination against the route table and ask which listed route is the most specific match.

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

Work in two passes. Keep the route table from Step 6 visible. First decide which listed prefixes match each destination.

For example, `172.20.30.99` starts with `172.20.`, so it matches `172.20.0.0/16`. It also starts with `172.20.30.`, so it matches `172.20.30.0/24`. It is not exactly `172.20.30.42`, so it does not match the `/32`.

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

Run the lookups and compare them to your predictions:

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

Remove the `/32` route:

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

Now remove the `/24`:

```sh
ip -n addrmatch route delete 172.20.30.0/24
```

The same destination falls back again:

```text
172.20.30.42 via 10.0.0.2 dev broad0 src 10.0.0.1
```

This is the core rule:

> Linux does not choose the first matching route. It chooses the longest matching route.

## Roll Back

Delete the namespace:

```sh
ip netns delete addrmatch
```

Confirm it is gone:

```sh
ip netns list | grep -E '^addrmatch( |$)' || true
```

No output is the expected result. Deleting the namespace removes the dummy interfaces and all routes inside it.

## Repeat With the Validation Script

After you have built the lab manually, you can rerun the validated script when you want a clean repeat or transcript:

```sh
bash experiments/labs/addresses-longest-match/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/addresses-longest-match/run.sh
```

The transcript used to validate this chapter is:

```text
experiments/transcripts/addresses-longest-match-20260616T124649Z.txt
```

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

You will see the same idea again in two different roles:

| Later chapter | What changes |
| --- | --- |
| Pocket Internet with Static Routes | Route tables carry real traffic between namespaces, so request and reply paths matter. |
| Pocket Internet Route Selection | The same lookup rule is placed inside an edge router with different exits, so the selected route changes where traffic would leave the network. |

## Verify Before Proceeding

- [ ] You can explain the difference between one address and a prefix.
- [ ] You can explain why `/32` is more specific than `/24`.
- [ ] You can predict which route wins when several routes match.
- [ ] You can use `ip route get` to check Linux's selected route.
- [ ] You can explain why removing a more-specific route changes the selected path.

## Before You Continue

You can now explain:

- the difference between one address and a prefix,
- why `/32` means one exact IPv4 address,
- why the most specific matching route wins,
- how `ip route get` reveals Linux's selected route.

Still okay if fuzzy:

- binary subnet math,
- source address selection,
- how these route choices look inside a larger topology.

Next we need:

- to use these ideas in Pocket Internet,
- to make service loopbacks reachable across multiple namespaces,
- to feel why writing routes by hand gets tiring,
- to come back to route selection later inside a Pocket Internet edge router.

## References

- `linux-ip-route`: use this for exact Linux route syntax and route lookup behavior.
- `rfc-4193`: use this later for IPv6 unique local address background.
- Transcript: `experiments/transcripts/addresses-longest-match-20260616T124649Z.txt`.
