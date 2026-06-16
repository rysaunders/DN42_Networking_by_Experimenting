# Pocket Internet Route Selection

## Reader Starting Point

This chapter assumes you have completed Pocket Internet with Static Routes. You should know what a namespace, interface, address, prefix, connected route, next hop, route lookup, service loopback, and static route are.

You have also seen longest-prefix match in a small isolated lab. This chapter puts that idea back into the Pocket Internet model.

The goal is to answer one question:

> When a Pocket Internet router has several routes that could match a destination, which exit does it choose?

## New Terms

| Term | Plain-language meaning | Example |
| --- | --- | --- |
| Edge router | A router at the edge of a network, where traffic leaves toward another network. | `pocket-rs-edge` |
| Exit | The interface and next hop a route points toward. | `via 10.52.1.2 dev edge-service0` |
| Fallback route | A broader route that is used only when no more-specific route matches. | `172.20.0.0/16` after a `/24` is removed |

## Mental Model

In the previous Pocket Internet lab, routes mostly pointed at exact service loopbacks:

```text
172.20.3.1/32 via 10.42.12.2 dev as1-as2
```

That made each lookup simple: there was one route for one service address.

Real route tables often contain overlapping instructions:

```text
172.20.0.0/16     via 10.52.0.2 dev edge-transit0
172.20.3.0/24     via 10.52.1.2 dev edge-service0
172.20.3.42/32    via 10.52.2.2 dev edge-host0
```

Read those as:

- anything in `172.20.0.0/16` can leave through transit,
- anything in `172.20.3.0/24` has a more specific service-side exit,
- exactly `172.20.3.42` has the most specific instruction.

The destination `172.20.3.42` matches all three routes. Linux chooses the most specific matching route.

## Why It Matters

Pocket Internet is heading toward BGP, where routers will learn routes instead of typing every route by hand. BGP can add, remove, and replace route entries, but it does not remove the kernel's basic lookup rule.

The kernel still asks:

> Which route is the best match for this destination?

If you can predict that decision from `ip route`, dynamic routing becomes much less mysterious.

## Safety Boundaries

- The lab uses one temporary Linux network namespace.
- The lab uses dummy interfaces and route lookups, so no packets leave the machine.
- The lab does not change the real host's route table or default route.
- Rollback deletes the namespace, interfaces, and routes.

## Lab

Build this lab by typing the commands yourself. The validation script exists so you can rerun the experiment later, but the learning path is the manual path.

These commands must run with root privileges inside the Linux environment because network namespaces, interfaces, and routes are system-level objects. On macOS, use an OrbStack shell:

```sh
orb
```

Then run the commands from that Linux shell as root, or prefix them with `sudo`.

The repeatable validation script lives at:

```text
experiments/labs/pocket-internet-route-selection/run.sh
```

The validated transcript for this chapter is:

```text
experiments/transcripts/pocket-internet-route-selection-20260616T185554Z.txt
```

## What You Will Build

You will create one temporary namespace:

```text
pocket-rs-edge
```

Think of it as one Pocket Internet edge router. It has three local exits:

| Interface | Connected prefix | Role |
| --- | --- | --- |
| `edge-transit0` | `10.52.0.0/30` | broad transit exit |
| `edge-service0` | `10.52.1.0/30` | more-specific service exit |
| `edge-host0` | `10.52.2.0/30` | exact-host exit |

This lab studies route lookup, not packet delivery. The next-hop addresses are stand-ins for neighboring routers that would exist on those links in a larger topology.

Picture the namespace like this:

```text
                         destinations
                         172.20.0.0/16
                              |
+-----------------------------+-----------------------------+
| pocket-rs-edge                                            |
|                                                           |
|  edge-transit0       edge-service0        edge-host0       |
|  10.52.0.1/30        10.52.1.1/30         10.52.2.1/30    |
|       |                   |                    |           |
|  via 10.52.0.2       via 10.52.1.2        via 10.52.2.2   |
|  172.20.0.0/16       172.20.3.0/24        172.20.3.42/32  |
+-----------------------------------------------------------+
```

The routes are not three different packets. They are three possible instructions in one route table. Route lookup chooses the most specific instruction that matches the destination.

## Step 1: Clean Up Any Old Lab State

If you ran this lab before, delete the old namespace first:

```sh
ip netns delete pocket-rs-edge 2>/dev/null || true
```

Confirm it is gone:

```sh
ip netns list | grep -E '^pocket-rs-edge( |$)' || true
```

No output is the expected result.

The first command deletes the namespace if it exists and hides the harmless error if it does not. The second command prints the namespace only if it is still present.

## Step 2: Create the Edge Router Namespace

Create the namespace:

```sh
ip netns add pocket-rs-edge
```

Check that Linux sees it:

```sh
ip netns list
```

Expected output includes:

```text
pocket-rs-edge
```

This namespace is one isolated network stack. It has its own interfaces and route table.

## Step 3: Create Local Exits

Create three dummy interfaces inside the namespace:

```sh
ip -n pocket-rs-edge link add edge-transit0 type dummy
ip -n pocket-rs-edge link add edge-service0 type dummy
ip -n pocket-rs-edge link add edge-host0 type dummy
```

A dummy interface is a local-only interface. It is useful here because we want to study route selection without needing packets to reach a real neighbor.

The interface names describe their roles:

- `edge-transit0` is the broad exit,
- `edge-service0` is the more-specific service exit,
- `edge-host0` is the exact-host exit.

## Step 4: Assign Interface Addresses

Assign one address-with-prefix to each exit:

```sh
ip -n pocket-rs-edge addr add 10.52.0.1/30 dev edge-transit0
ip -n pocket-rs-edge addr add 10.52.1.1/30 dev edge-service0
ip -n pocket-rs-edge addr add 10.52.2.1/30 dev edge-host0
```

Each command assigns one specific address to one interface. The `/30` tells Linux the size of the local link around that address.

For `edge-transit0`, that means:

- local interface address: `10.52.0.1`,
- connected route created by Linux: `10.52.0.0/30`,
- plausible next-hop address on that link: `10.52.0.2`.

This matters because a route with `via 10.52.0.2 dev edge-transit0` depends on `10.52.0.2` being on a connected route for `edge-transit0`.

## Step 5: Bring Interfaces Up

Bring up loopback and both exits:

```sh
ip -n pocket-rs-edge link set lo up
ip -n pocket-rs-edge link set edge-transit0 up
ip -n pocket-rs-edge link set edge-service0 up
ip -n pocket-rs-edge link set edge-host0 up
```

Now inspect the connected routes Linux created automatically:

```sh
ip -n pocket-rs-edge route
```

Expected output:

```text
10.52.0.0/30 dev edge-transit0 proto kernel scope link src 10.52.0.1
10.52.1.0/30 dev edge-service0 proto kernel scope link src 10.52.1.1
10.52.2.0/30 dev edge-host0 proto kernel scope link src 10.52.2.1
```

Read the first line as:

> Addresses inside `10.52.0.0/30` are local to `edge-transit0`.

That is why `10.52.0.2` can be used as a next hop for routes through `edge-transit0`.

Before adding the real experiment routes, prove the connected-route rule by trying an off-link next hop:

```sh
ip -n pocket-rs-edge route add 172.20.99.0/24 via 10.52.9.2 dev edge-transit0
```

Expected output:

```text
Error: Nexthop has invalid gateway.
```

Linux rejects the route because `10.52.9.2` is not inside the connected `10.52.0.0/30` route for `edge-transit0`. The next-hop address has to look local on the interface named by `dev`.

## Step 6: Add Overlapping Routes

Install three routes:

```sh
ip -n pocket-rs-edge route add 172.20.0.0/16 via 10.52.0.2 dev edge-transit0
ip -n pocket-rs-edge route add 172.20.3.0/24 via 10.52.1.2 dev edge-service0
ip -n pocket-rs-edge route add 172.20.3.42/32 via 10.52.2.2 dev edge-host0
```

Then inspect the route table:

```sh
ip -n pocket-rs-edge route
```

Expected output includes:

```text
172.20.0.0/16 via 10.52.0.2 dev edge-transit0
172.20.3.0/24 via 10.52.1.2 dev edge-service0
172.20.3.42 via 10.52.2.2 dev edge-host0
```

The exact host route may display as `172.20.3.42` instead of `172.20.3.42/32`. In IPv4 route output, a single address route is a `/32` even when Linux omits the suffix.

## Predict Before Revealing

Keep the route table visible while you answer these.

For each destination, choose the route you expect Linux to use:

| Destination | Matching routes | Predicted winner |
| --- | --- | --- |
| `172.20.3.42` | `/16`, `/24`, `/32` | ? |
| `172.20.3.99` | `/16`, `/24` | ? |
| `172.20.9.9` | `/16` | ? |

??? question "Reveal the expected winners"

    | Destination | Winner | Why |
    | --- | --- | --- |
    | `172.20.3.42` | `172.20.3.42/32` | `/32` is the most specific match. |
    | `172.20.3.99` | `172.20.3.0/24` | It matches `/24` and `/16`; `/24` is more specific. |
    | `172.20.9.9` | `172.20.0.0/16` | It matches only the broad `/16`. |

## Step 7: Ask Linux Which Route Wins

Now use route lookup to reveal the kernel's decision:

```sh
ip -n pocket-rs-edge route get 172.20.3.42
ip -n pocket-rs-edge route get 172.20.3.99
ip -n pocket-rs-edge route get 172.20.9.9
```

Expected output:

```text
172.20.3.42 via 10.52.2.2 dev edge-host0 src 10.52.2.1 uid 0
172.20.3.99 via 10.52.1.2 dev edge-service0 src 10.52.1.1 uid 0
172.20.9.9 via 10.52.0.2 dev edge-transit0 src 10.52.0.1 uid 0
```

The first two destinations leave through different exits:

- `172.20.3.42` uses the exact host route through `edge-host0`,
- `172.20.3.99` uses the `/24` service route.

The third destination leaves through `edge-transit0` because only the broad `/16` route matches.

## Step 8: Remove the Exact Host Route

Delete the `/32` route:

```sh
ip -n pocket-rs-edge route delete 172.20.3.42/32
```

Ask again:

```sh
ip -n pocket-rs-edge route get 172.20.3.42
```

Expected output:

```text
172.20.3.42 via 10.52.1.2 dev edge-service0 src 10.52.1.1 uid 0
```

The output still points at `edge-service0`, but the reason changed. The exact host route is gone, so Linux falls back to the `172.20.3.0/24` route.

This is route fallback: removing a more-specific match reveals the next-best broader match.

## Step 9: Remove the Service Route

Delete the `/24` route:

```sh
ip -n pocket-rs-edge route delete 172.20.3.0/24
```

Ask again:

```sh
ip -n pocket-rs-edge route get 172.20.3.42
```

Expected output:

```text
172.20.3.42 via 10.52.0.2 dev edge-transit0 src 10.52.0.1 uid 0
```

Now only the broad `172.20.0.0/16` route matches, so the packet would leave through `edge-transit0`.

## Step 10: Roll Back

Delete the namespace:

```sh
ip netns delete pocket-rs-edge
```

Confirm cleanup:

```sh
ip netns list | grep -E '^pocket-rs-edge( |$)' || true
```

No output is the expected result.

The validation script performs cleanup silently before showing the namespace check. The manual command above is the visible version of the same rollback.

## Repeat With the Validation Script

After you have built the lab manually, you can rerun the validated path from the repository root:

```sh
bash experiments/labs/pocket-internet-route-selection/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/pocket-internet-route-selection/run.sh
```

## What You Learned

- A route table can contain overlapping routes.
- Linux chooses the most specific matching route.
- `ip route get` shows the route Linux would actually use.
- A route's next hop must be reachable through a connected route.
- Removing a more-specific route can make traffic fall back to a broader route.

## How This Connects to DN42

DN42 routers receive many prefixes from peers. Some routes are broad, some are specific, and some may disappear when a peer withdraws them.

BIRD and BGP will decide which routes to install, but the Linux kernel still performs route lookup. The packet leaves through the route that best matches its destination in the installed route table.
