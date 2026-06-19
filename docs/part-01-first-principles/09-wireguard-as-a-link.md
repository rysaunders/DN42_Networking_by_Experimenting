# Build and Verify a WireGuard Link

## Reader Starting Point

This chapter assumes you have completed the tunnel-model chapter. You should know what a namespace, interface, address, prefix, route lookup, VPN, tunnel, underlay, overlay, inner packet, and outer packet are.

You have already seen the idea:

```text
underlay = the path that carries the tunnel packets
overlay  = the link the lab network wants to use
```

Now you will build only that link.

No BIRD. No BGP. No four-router Pocket Internet yet.

That is deliberate. Before asking a routing daemon to use a WireGuard link, you should be able to prove that the link itself works.

## New Terms

| Term | Plain-language meaning | Example in this lab |
| --- | --- | --- |
| WireGuard | A VPN protocol that creates encrypted tunnel interfaces. | The `wg23` interface inside each namespace |
| Private key | A secret WireGuard key that stays local. | `/tmp/wireguard-point-to-point/as2.key` |
| Public key | The key you give to the peer. | `as2.pub` |
| Endpoint | The underlay IP and UDP port where a peer receives WireGuard packets. | `192.0.2.2:51824` |
| Handshake | Evidence that the WireGuard peers exchanged setup traffic. | `latest handshake` in `wg show` |
| AllowedIPs | WireGuard's peer-selection and packet-allow list. | `10.42.23.2/32` on AS2's peer |

## Question

Can two namespaces build an encrypted point-to-point link over an ordinary local veth underlay?

## Hypothesis

If `pocket-as2` and `pocket-as3` have an underlay path, and each side has a WireGuard interface with matching peer keys, endpoints, and allowed overlay neighbor addresses, then AS2 should be able to ping AS3's overlay address through `wg23`.

## Lab Mental Model

The underlay is the carrier path:

```text
pocket-as2 as2-underlay 192.0.2.1  <---- veth ---->  192.0.2.2 as3-underlay pocket-as3
```

The overlay is the encrypted point-to-point link:

```text
pocket-as2 wg23 10.42.23.1  <==== WireGuard ====>  10.42.23.2 wg23 pocket-as3
```

When you ping `10.42.23.2`, Linux gives the inner packet to `wg23`. WireGuard wraps it, encrypts it, and sends an outer UDP packet to `192.0.2.2:51824` across the underlay.

## Why This Lab Matters

The next chapter runs BGP over this link. Real DN42 peers often do the same thing across the public Internet.

But BGP should not be your first proof that WireGuard works. This chapter gives you a smaller checkpoint:

1. the underlay works,
2. the WireGuard interface exists,
3. the peers can handshake,
4. overlay traffic crosses the tunnel.

## Safety Boundaries

Safety level: WireGuard lab.

- The lab uses only two temporary Linux network namespaces.
- The lab creates WireGuard interfaces only inside `pocket-as2` and `pocket-as3`.
- The underlay is a local veth link, not the public Internet.
- The lab does not use `wg-quick`.
- The lab does not add host default routes.
- The lab does not touch public DN42 peers.
- Rollback deletes the namespaces and removes generated keys with `/tmp/wireguard-point-to-point`.
- This chapter creates and deletes only `pocket-as2` and `pocket-as3`.

Before the lab, capture the host baseline:

```sh
ip netns list
ip route get 1.1.1.1
```

## Lab Requirements

Run this chapter inside the Linux lab environment from a root shell. The commands below are written without `sudo` so they stay readable and match the validation transcript style.

Check the required tools before building the link:

```sh
id
ip -V
wg --version
```

Expected observations:

- `id` should show `uid=0(root)`. If it does not, enter a root lab shell before continuing.
- `wg --version` should print the WireGuard tools version.
- If `wg` is missing, install `wireguard-tools` in the Linux lab environment.
- If `ip -n pocket-as2 link add wg23 type wireguard` later fails with `Operation not supported`, the environment has the tools but not usable WireGuard kernel support.

## Lab Continuity Note

This chapter is a manual-first WireGuard mechanics lab. The repeatable validation script builds only this two-namespace point-to-point link:

```text
experiments/labs/wireguard-point-to-point/run.sh
```

The validated transcript for this experiment is:

```text
experiments/transcripts/wireguard-point-to-point-20260618T213251Z.txt
```

This chapter intentionally stops before BIRD and BGP so the WireGuard mechanics are not buried under routing-daemon configuration.

## What You Will Build

You will create two AS-shaped namespaces:

| Namespace | Role |
| --- | --- |
| `pocket-as2` | left side of the tunnel |
| `pocket-as3` | right side of the tunnel |

The link has two layers:

| Layer | Interface(s) | Prefix |
| --- | --- | --- |
| Underlay | `as2-underlay`, `as3-underlay` | `192.0.2.0/30` |
| Overlay | `wg23`, `wg23` | `10.42.23.0/30` |

## Step 1: Clean Up Any Old Lab State

Delete old namespaces and temporary files for this lab:

```sh
ip netns delete pocket-as2 2>/dev/null || true
ip netns delete pocket-as3 2>/dev/null || true
rm -rf /tmp/wireguard-point-to-point
```

Confirm cleanup:

```sh
ip netns list | grep -E '^(pocket-as2|pocket-as3)( |$)' || true
```

No output is the expected result.

## Step 2: Create The Two Namespaces

Create a working directory and two namespaces:

```sh
install -d -m 700 /tmp/wireguard-point-to-point
stat -c "%a %n" /tmp/wireguard-point-to-point

ip netns add pocket-as2
ip netns add pocket-as3
```

Bring up each loopback:

```sh
ip -n pocket-as2 link set lo up
ip -n pocket-as3 link set lo up
```

At this point, the namespaces exist but have no path between them.

## Step 3: Build The Underlay

Create the veth pair that will carry encrypted WireGuard packets:

```sh
ip link add as2-underlay type veth peer name as3-underlay
ip link set as2-underlay netns pocket-as2
ip link set as3-underlay netns pocket-as3
```

Add underlay addresses:

```sh
ip -n pocket-as2 addr add 192.0.2.1/30 dev as2-underlay
ip -n pocket-as3 addr add 192.0.2.2/30 dev as3-underlay
```

Bring up the underlay interfaces:

```sh
ip -n pocket-as2 link set as2-underlay up
ip -n pocket-as3 link set as3-underlay up
```

Prove the underlay works:

```sh
ip -n pocket-as2 route get 192.0.2.2
ip netns exec pocket-as2 ping -c 1 -W 1 192.0.2.2
```

Expected route lookup:

```text
192.0.2.2 dev as2-underlay ...
```

If this fails, stop here. WireGuard has nowhere to send encrypted packets.

!!! success "What this proves"
    The underlay path between the two namespaces is working.

!!! warning "What this does not prove"
    It does not prove WireGuard is working yet. At this point, only the network that will carry encrypted packets has been tested.

## Step 4: Generate WireGuard Keys

Each side gets a private key and a public key:

```sh title="Generate WireGuard private and public keys from the root Linux shell"
( umask 077; wg genkey > /tmp/wireguard-point-to-point/as2.key )
wg pubkey < /tmp/wireguard-point-to-point/as2.key > /tmp/wireguard-point-to-point/as2.pub

( umask 077; wg genkey > /tmp/wireguard-point-to-point/as3.key )
wg pubkey < /tmp/wireguard-point-to-point/as3.key > /tmp/wireguard-point-to-point/as3.pub
```

Print only public keys:

```sh
cat /tmp/wireguard-point-to-point/as2.pub
cat /tmp/wireguard-point-to-point/as3.pub
```

Private keys stay local. Public keys are what peers exchange.

The parentheses keep the stricter `umask` scoped to each private-key command. That makes the private key files readable only by their owner without changing file permissions for later commands in the same shell.

## Step 5: Create WireGuard Overlay Interfaces

Create `wg23` inside AS2 and AS3:

```sh
ip -n pocket-as2 link add wg23 type wireguard
ip -n pocket-as3 link add wg23 type wireguard
```

Add the overlay link addresses:

```sh
ip -n pocket-as2 addr add 10.42.23.1/30 dev wg23
ip -n pocket-as3 addr add 10.42.23.2/30 dev wg23
```

This reuses the familiar AS2-AS3 link prefix from earlier Pocket Internet labs. The difference is the interface carrying it.

## Step 6: Configure WireGuard Peers

Read the public keys into shell variables:

```sh title="Read WireGuard public keys into shell variables"
AS2_PUB="$(cat /tmp/wireguard-point-to-point/as2.pub)"
AS3_PUB="$(cat /tmp/wireguard-point-to-point/as3.pub)"
```

Configure AS2:

```sh title="Configure the AS2 WireGuard peer"
ip netns exec pocket-as2 wg set wg23 \
  private-key /tmp/wireguard-point-to-point/as2.key \
  listen-port 51823 \
  peer "$AS3_PUB" \
  allowed-ips 10.42.23.2/32 \
  endpoint 192.0.2.2:51824
```

Configure AS3:

```sh title="Configure the AS3 WireGuard peer"
ip netns exec pocket-as3 wg set wg23 \
  private-key /tmp/wireguard-point-to-point/as3.key \
  listen-port 51824 \
  peer "$AS2_PUB" \
  allowed-ips 10.42.23.1/32 \
  endpoint 192.0.2.1:51823
```

Bring both interfaces up:

```sh
ip -n pocket-as2 link set wg23 up
ip -n pocket-as3 link set wg23 up
```

Read the AS2 peer configuration like this:

```text
private-key ...            use AS2's private identity
listen-port 51823          receive WireGuard packets on UDP port 51823
peer "$AS3_PUB"            the other side should prove it owns AS3's private key
allowed-ips 10.42.23.2/32  send this overlay neighbor through that peer
endpoint 192.0.2.2:51824   reach that peer at this underlay address and port
```

For now, `AllowedIPs` includes only the other overlay address. The next chapter broadens that list so service-loopback traffic can cross the tunnel.

## Step 7: Compare Underlay And Overlay Route Lookups

Ask AS2 how it reaches the underlay endpoint:

```sh
ip -n pocket-as2 route get 192.0.2.2
```

Expected output uses `as2-underlay`.

Ask AS2 how it reaches the overlay neighbor:

```sh
ip -n pocket-as2 route get 10.42.23.2
```

Expected output uses `wg23`.

Those two lookups are the whole model:

| Destination | Meaning | Interface Linux chooses |
| --- | --- | --- |
| `192.0.2.2` | underlay endpoint | `as2-underlay` |
| `10.42.23.2` | overlay neighbor | `wg23` |

## Step 8: Prove The WireGuard Link Works

Ping the overlay neighbor:

```sh
ip netns exec pocket-as2 ping -c 2 -W 1 10.42.23.2
```

Then inspect WireGuard:

```sh title="Inspect WireGuard state inside pocket-as2"
ip netns exec pocket-as2 wg show wg23
```

Look for:

```text
latest handshake: ...
transfer: ...
```

A handshake says the peers exchanged WireGuard setup traffic. The transfer counters should increase after ping.

!!! success "What this proves"
    The WireGuard peers can exchange tunnel setup traffic, and packets are crossing `wg23`.

!!! warning "What this does not prove"
    It does not prove BGP or service-loopback routing is working. This step proves the tunnel link, not the whole Pocket Internet.

Inspect AS3 too:

```sh title="Inspect WireGuard state inside pocket-as3"
ip netns exec pocket-as3 wg show wg23
```

Both sides should show the same peer relationship from opposite directions.

## Troubleshooting Branches

### Underlay Fails

If this fails:

```sh
ip netns exec pocket-as2 ping -c 1 -W 1 192.0.2.2
```

fix the underlay before changing WireGuard. The tunnel cannot work if its carrier path is broken.

Check that the underlay interfaces are up:

```sh
ip -n pocket-as2 link show as2-underlay
ip -n pocket-as3 link show as3-underlay
```

### No Handshake

Check:

- AS2 endpoint points at `192.0.2.2:51824`,
- AS3 endpoint points at `192.0.2.1:51823`,
- each side uses its own private key,
- each side uses the other side's public key,
- both `wg23` interfaces are up.

Use:

```sh title="Inspect WireGuard state on both tunnel endpoints"
ip netns exec pocket-as2 wg show wg23
ip netns exec pocket-as3 wg show wg23
```

### Handshake Works But Overlay Ping Fails

Check `AllowedIPs`.

For this chapter:

- AS2's peer for AS3 should allow `10.42.23.2/32`.
- AS3's peer for AS2 should allow `10.42.23.1/32`.

If those entries are wrong, WireGuard may have a peer but still refuse to carry the inner packet you are trying to send.

## Rollback

Delete namespaces and generated files:

```sh
ip netns delete pocket-as2 2>/dev/null || true
ip netns delete pocket-as3 2>/dev/null || true
rm -rf /tmp/wireguard-point-to-point
```

Prove cleanup worked:

```sh
if ip netns list | grep -E '^(pocket-as2|pocket-as3)( |$)'; then
  echo 'leftover WireGuard lab namespaces found'
  exit 1
fi
echo 'no WireGuard lab namespaces remain'
```

Confirm the public default path still uses the normal host route:

```sh
ip route get 1.1.1.1
```

## What You Can Now Explain

You can now explain:

- why WireGuard still needs an underlay path,
- why the overlay address uses `wg23` while the endpoint address uses the underlay interface,
- why WireGuard needs private keys, public keys, endpoints, and `AllowedIPs`,
- what a handshake proves,
- why a handshake is useful but does not yet prove BGP or service routing.

## Still Okay If Fuzzy

It is okay if these are still fuzzy:

- BGP over WireGuard,
- WireGuard carrying service-loopback traffic,
- MTU sizing,
- NAT traversal and persistent keepalive,
- `wg-quick`,
- host-to-lab access,
- real DN42 peer expectations.

The next chapter adds BGP back on top of the tunnel.

## Next We Need

Now that the encrypted point-to-point link works, the next question is whether Pocket Internet can use it as an ordinary routed link.

That means:

1. rebuild the four-AS Pocket Internet shape,
2. keep AS2-AS3 as WireGuard instead of veth,
3. run BIRD and BGP across `wg23`,
4. prove service-loopback traffic still crosses the tunnel.

## References

- `wireguard-quickstart`
- `wireguard-netns`
