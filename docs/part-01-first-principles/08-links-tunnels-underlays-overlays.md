# Links, Tunnels, Underlays, and Overlays

## Reader Starting Point

You have already built Pocket Internet with visible links. A veth pair felt like a cable because it had two ends:

```text
pocket-as2 as2-as3  <---- veth ---->  as3-as2 pocket-as3
```

You have also seen that BGP does not create links. BGP uses links that already exist. If two neighbors can reach each other, BGP can exchange routes across that path.

Now we need one more idea before replacing a Pocket Internet link with WireGuard:

> A tunnel is a link-shaped thing carried inside another network.

That sentence is small, but it is the whole trick.

## New Terms

| Term | Plain-language meaning | Example |
| --- | --- | --- |
| VPN | A way to create a private-looking network path across another network. | WireGuard creates a private link between two peers. |
| Tunnel | A logical link carried inside another packet path. | A WireGuard link carried over an underlay veth pair. |
| Inner packet | The packet the lab network thinks it is sending. | `10.42.23.1 -> 10.42.23.2` |
| Outer packet | The packet that carries the inner packet across the underlay. | `192.0.2.1 -> 192.0.2.2` |
| Underlay | The network that carries tunnel packets. | The veth pair with `192.0.2.0/30`. |
| Overlay | The logical network created on top of the underlay. | The WireGuard link with `10.42.23.0/30`. |

## First, What Is A VPN?

You do not need to know corporate VPN products to understand this chapter.

In this book, a VPN is a tool that makes two network stacks behave as if they share a private link, even though the packets are actually crossing some other network first.

The private-looking link is not magic. It still needs a path underneath it.

In a real DN42 peer, that underneath path is usually the public Internet:

```text
your router
  -> your ISP
  -> public Internet
  -> peer's ISP
  -> peer router
```

In Pocket Internet, we do not want to depend on the public Internet yet. So the lab uses a veth pair as the underneath path:

```text
pocket-as2 as2-underlay  <---- veth ---->  as3-underlay pocket-as3
```

That veth pair is not the link we want BGP to care about. It is the carrier path for the tunnel.

## Why A Veth Pair Still Exists

This is the confusing part, so slow down here.

When we say "replace the AS2-AS3 veth link with WireGuard," we are replacing the routed Pocket Internet link:

```text
Before:
pocket-as2 as2-as3 10.42.23.1  <---- veth ---->  10.42.23.2 as3-as2 pocket-as3
```

After the replacement, BGP should no longer use an `as2-as3` veth interface. BGP should use a WireGuard interface:

```text
After:
pocket-as2 wg23 10.42.23.1  <==== WireGuard ====>  10.42.23.2 wg23 pocket-as3
```

But WireGuard itself still has to send encrypted packets somewhere. In the local lab, those encrypted packets cross a different veth pair:

```text
Carrier path:
pocket-as2 as2-underlay 192.0.2.1  <---- veth ---->  192.0.2.2 as3-underlay pocket-as3
```

So there are two layers:

| Layer | What it is | Addresses in the lab | Who cares about it |
| --- | --- | --- | --- |
| Underlay | The carrier network for encrypted tunnel packets. | `192.0.2.1`, `192.0.2.2` | WireGuard endpoints |
| Overlay | The logical routed link created by WireGuard. | `10.42.23.1`, `10.42.23.2` | Linux routing and BGP |

That is why the lab still creates a veth pair. We are not using it as the AS2-AS3 Pocket Internet link. We are using it as the ground the tunnel stands on.

## Packet Inside Packet

Imagine AS2 sends a BGP packet to AS3.

From BGP's point of view, the packet is simple:

```text
inner packet:
10.42.23.1 -> 10.42.23.2
```

Linux sees that `10.42.23.2` is reachable through `wg23`, so it gives the packet to WireGuard.

WireGuard then wraps and encrypts that packet. The wrapped packet needs to cross the underlay:

```text
outer packet:
192.0.2.1 -> 192.0.2.2
UDP destination port 51824
```

At AS3, WireGuard unwraps the outer packet and hands the inner packet back to Linux:

```text
delivered inner packet:
10.42.23.1 -> 10.42.23.2
```

The inner packet is what the overlay sees. The outer packet is what the underlay carries.

The same idea applies to service-loopback reachability. If AS1 sends a packet toward AS3's service loopback, the packet eventually reaches AS2. AS2's route can say:

```text
172.20.3.1 via 10.42.23.2 dev wg23
```

That means the next hop is AS3's overlay address, but the inner destination is still `172.20.3.1`. WireGuard must be willing to carry that inner destination through the AS3 peer. This is why the BGP-over-WireGuard lab's `AllowedIPs` list includes service loopbacks, not only the tunnel neighbor address.

## A Small Note On Layers

You may have heard of the OSI model. You do not need the whole seven-layer chart for this lab.

The useful idea is simpler: one network thing can ride inside another network thing.

In this lab:

- BGP is an application-level routing conversation between routers.
- The BGP packets use the overlay addresses on `wg23`.
- WireGuard encrypts those packets and sends them as UDP across the underlay.
- The underlay veth pair carries those UDP packets between namespaces.

So when someone says "overlay" or "underlay," they are usually pointing at this stacked relationship. They are not saying the underlay is better or more real. They are saying one packet path is carrying another.

## The Two Route Lookups Are Different

This is the practical test you will run after the next lab builds the namespaces and WireGuard interface. The commands are shown here so the model has something concrete to attach to; they will not work until the lab exists.

If AS2 asks how to reach the overlay neighbor:

```sh
ip -n pocket-as2 route get 10.42.23.2
```

the answer should point at WireGuard:

```text
10.42.23.2 dev wg23 ...
```

If AS2 asks how to reach the underlay endpoint:

```sh
ip -n pocket-as2 route get 192.0.2.2
```

the answer should point at the underlay veth:

```text
192.0.2.2 dev as2-underlay ...
```

Those are both true at the same time. That is not a contradiction. It is the tunnel model.

## What Changes And What Stays The Same

When the AS2-AS3 link changes from veth to WireGuard:

| Question | Before WireGuard | After WireGuard |
| --- | --- | --- |
| What interface does BGP use between AS2 and AS3? | `as2-as3` / `as3-as2` | `wg23` |
| What addresses do BGP neighbors use? | `10.42.23.1` and `10.42.23.2` | `10.42.23.1` and `10.42.23.2` |
| Does Linux still do route lookup? | Yes | Yes |
| Does BIRD still exchange routes? | Yes | Yes |
| Is there now an underlay carrier path? | No | Yes, `192.0.2.0/30` |
| Does this touch real DN42? | No | No |

The link implementation changes. The routing model stays recognizable.

## Where This Points

This idea is why DN42 can work over the public Internet.

Two peers do not need a physical cable between them. They need:

- some underlay path that can carry encrypted packets,
- a tunnel interface on each side,
- addresses on that tunnel interface,
- routing software that exchanges reachability across the tunnel.

Pocket Internet will use a local veth underlay first. Later, DN42 uses the same shape with a real underlay path.

## What You Can Now Explain

You can now explain:

- what a VPN means in this book,
- why a tunnel still needs an existing network path,
- why the WireGuard lab still creates a veth pair,
- the difference between an inner packet and an outer packet,
- why `10.42.23.2` and `192.0.2.2` are not competing addresses,
- why BGP can run over WireGuard without caring that the link is encrypted.

## Still Okay If Fuzzy

It is okay if these are still fuzzy:

- how WireGuard keys work,
- what `AllowedIPs` does,
- what a WireGuard handshake proves,
- how BIRD is configured over the tunnel,
- how this maps onto a real DN42 peer.

Those are the job of the next two labs.

## Next We Need

Now that the two-layer model is named, we can build it in two passes:

1. create the underlay path,
2. create the WireGuard overlay,
3. prove the tunnel works by itself,
4. run BGP over the overlay,
5. prove routed service-loopback traffic crosses the tunnel.
