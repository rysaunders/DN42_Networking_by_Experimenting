# Replace a Pocket Internet Link with WireGuard

## Reader Starting Point

This chapter assumes you have completed the BGP, service, and tunnel-model chapters. You should know what a namespace, service loopback, route lookup, return path, BIRD, BGP session, route advertisement, kernel route, convergence, listener, application traffic, underlay, and overlay are.

You have used veth pairs as links between Pocket Internet routers. You have also seen the tunnel model: WireGuard creates an overlay link, but the encrypted WireGuard packets still need an underlay path.

Now you will build that model by replacing one routed Pocket Internet veth link with WireGuard.

The important idea is:

> The link changes. The routing model should still look familiar.

This is still Pocket Internet work. You are not creating a DN42 peer yet. You are learning how an encrypted tunnel can behave like a point-to-point link inside the lab.

## New Terms

| Term | Plain-language meaning | Example in this lab |
| --- | --- | --- |
| Private key | A secret WireGuard key that stays local. | `/tmp/pocket-internet-wireguard-link/as2.key` |
| Public key | The key you give to the peer. | `as2.pub` |
| Endpoint | The underlay IP and UDP port where a peer receives WireGuard packets. | `192.0.2.2:51824` |
| Handshake | Evidence that the WireGuard peers exchanged cryptographic setup traffic. | `latest handshake` in `wg show` |
| AllowedIPs | WireGuard's peer-selection and packet-allow list. | `172.20.3.1/32` on AS2's peer |

## Question

Can one Pocket Internet link become a WireGuard tunnel while BGP-learned service-loopback reachability still works?

## Hypothesis

If `pocket-as2` and `pocket-as3` have an underlay path, and each side has a WireGuard interface with matching peer keys, endpoints, and allowed inner destinations, then the `10.42.23.0/30` AS2-AS3 link can move from veth to WireGuard.

If BIRD uses the WireGuard interface as the AS2-AS3 link, then `pocket-as1` should still reach `pocket-as3`'s service loopback through BGP-learned routes.

## Lab Mental Model

The old AS2-AS3 link was direct:

```text
pocket-as2 as2-as3  <---- veth ---->  as3-as2 pocket-as3
          10.42.23.1/30          10.42.23.2/30
```

The new shape has two layers:

```text
Underlay packet path:
pocket-as2 as2-underlay 192.0.2.1  <---- veth ---->  192.0.2.2 as3-underlay pocket-as3

Overlay routed link:
pocket-as2 wg23 10.42.23.1  <==== WireGuard ====>  10.42.23.2 wg23 pocket-as3
```

The underlay carries encrypted WireGuard packets. The overlay is the link that BIRD and Linux routing use.

You should end the lab with this path:

```text
pocket-as1
  -> pocket-as2
  -> wg23 over underlay
  -> pocket-as3 service loopback 172.20.3.1
```

## Why This Lab Matters

DN42 peers are usually not connected by physical cables. They use tunnels over the public Internet, and BGP runs across those tunnels.

This lab keeps the tunnel local and disposable. That lets you learn the mechanics before any real DN42 peer, public endpoint, or route policy enters the picture.

Host-to-lab access is also still out of scope. Later, an outside host or network reaching Pocket Internet starts to look like a controlled path toward a Pocket Internet AS. That is a useful idea, but this lab has one job: replace an internal Pocket Internet link.

## Safety Boundaries

Safety level: WireGuard lab.

- The lab uses only temporary Linux network namespaces.
- The lab creates WireGuard interfaces only inside `pocket-as2` and `pocket-as3`.
- The underlay is a local veth link, not the public Internet.
- The lab does not use `wg-quick`.
- The lab does not add host default routes.
- The lab does not touch public DN42 peers.
- Rollback deletes the namespaces and removes generated keys with `/tmp/pocket-internet-wireguard-link`.

Before the lab, capture the host baseline:

```sh
ip netns list
ip route get 1.1.1.1
```

## Lab Requirements

Run this chapter inside the Linux lab environment from a root shell. The commands below are written without `sudo` so they stay readable and match the validation transcript.

Check the required tools before building the topology:

```sh
id
ip -V
bird --version
command -v birdc
wg --version
```

Expected observations:

- `id` should show `uid=0(root)`. If it does not, enter a root lab shell before continuing.
- `bird --version` should report BIRD 2.
- `command -v birdc` should print a path.
- `wg --version` should print the WireGuard tools version.

If `wg` is missing, install `wireguard-tools` in the Linux lab environment. If `ip -n pocket-as2 link add wg23 type wireguard` later fails with `Operation not supported`, the environment has the tools but not usable WireGuard kernel support.

## Lab Continuity Note

This chapter rebuilds the Pocket Internet topology from scratch because every previous lab rolls back at the end. That is not ideal for reader ergonomics, and the project tracks a better continuity pattern separately.

For now, this chapter is deliberately self-contained:

- the validation script builds the whole lab,
- the manual steps below show the WireGuard replacement clearly,
- rollback removes everything.

The repeatable validation script lives at:

```text
experiments/labs/pocket-internet-wireguard-link/run.sh
```

The validated transcript for this experiment is:

```text
experiments/transcripts/pocket-internet-wireguard-link-20260618T112938Z.txt
```

## What You Will Build

You will create the same four AS-shaped namespaces:

| Namespace | Local AS | Service loopback |
| --- | --- | --- |
| `pocket-as1` | `4242420001` | `172.20.1.1/32` |
| `pocket-as2` | `4242420002` | `172.20.2.1/32` |
| `pocket-as3` | `4242420003` | `172.20.3.1/32` |
| `pocket-as4` | `4242420004` | `172.20.4.1/32` |

Three links remain veth routed links:

| Link | Prefix |
| --- | --- |
| AS1-AS2 | `10.42.12.0/30` |
| AS3-AS4 | `10.42.34.0/30` |
| AS4-AS1 | `10.42.41.0/30` |

The AS2-AS3 routed link becomes WireGuard:

| Layer | Interface(s) | Prefix |
| --- | --- | --- |
| Underlay | `as2-underlay`, `as3-underlay` | `192.0.2.0/30` |
| Overlay | `wg23`, `wg23` | `10.42.23.0/30` |

The underlay is local transport. The overlay is the link BIRD uses.

## Step 1: Clean Up Any Old Lab State

Delete old namespaces and temporary files:

```sh
for ns in pocket-as1 pocket-as2 pocket-as3 pocket-as4; do
  for dir in /tmp/pocket-internet-wireguard-link /tmp/pocket-internet-bgp; do
    if [ -f "${dir}/${ns}.pid" ]; then
      ip netns exec "$ns" kill "$(cat "${dir}/${ns}.pid")" 2>/dev/null || true
    fi
  done
done

ip netns delete pocket-as1 2>/dev/null || true
ip netns delete pocket-as2 2>/dev/null || true
ip netns delete pocket-as3 2>/dev/null || true
ip netns delete pocket-as4 2>/dev/null || true
rm -rf /tmp/pocket-internet-wireguard-link
```

Confirm cleanup:

```sh
ip netns list | grep -E '^(pocket-as1|pocket-as2|pocket-as3|pocket-as4)( |$)' || true
```

No output is the expected result.

## Step 2: Create Namespaces And The Veth Links That Remain

Create the namespaces:

```sh
mkdir -p /tmp/pocket-internet-wireguard-link

ip netns add pocket-as1
ip netns add pocket-as2
ip netns add pocket-as3
ip netns add pocket-as4
```

Create the three routed veth links that are not being replaced:

```sh
ip link add as1-as2 type veth peer name as2-as1
ip link set as1-as2 netns pocket-as1
ip link set as2-as1 netns pocket-as2

ip link add as3-as4 type veth peer name as4-as3
ip link set as3-as4 netns pocket-as3
ip link set as4-as3 netns pocket-as4

ip link add as4-as1 type veth peer name as1-as4
ip link set as4-as1 netns pocket-as4
ip link set as1-as4 netns pocket-as1
```

Notice what is missing: there is no `as2-as3` routed veth link. That is the link WireGuard will replace.

## Step 3: Create The AS2-AS3 Underlay

WireGuard still needs a path for its encrypted packets. In this local lab, that path is another veth pair:

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

Read that as:

- `192.0.2.1` is where AS2 sends encrypted WireGuard packets,
- `192.0.2.2` is where AS3 receives them,
- this is not the routed Pocket Internet service path.

## Step 4: Add Service And Remaining Link Addresses

Add service loopbacks:

```sh
ip -n pocket-as1 addr add 172.20.1.1/32 dev lo
ip -n pocket-as2 addr add 172.20.2.1/32 dev lo
ip -n pocket-as3 addr add 172.20.3.1/32 dev lo
ip -n pocket-as4 addr add 172.20.4.1/32 dev lo
```

Add the remaining veth link addresses:

```sh
ip -n pocket-as1 addr add 10.42.12.1/30 dev as1-as2
ip -n pocket-as2 addr add 10.42.12.2/30 dev as2-as1

ip -n pocket-as3 addr add 10.42.34.1/30 dev as3-as4
ip -n pocket-as4 addr add 10.42.34.2/30 dev as4-as3

ip -n pocket-as4 addr add 10.42.41.1/30 dev as4-as1
ip -n pocket-as1 addr add 10.42.41.2/30 dev as1-as4
```

Bring loopbacks, veth links, and underlay links up:

```sh
for ns in pocket-as1 pocket-as2 pocket-as3 pocket-as4; do
  ip -n "$ns" link set lo up
  ip netns exec "$ns" sysctl -w net.ipv4.ip_forward=1
done

ip -n pocket-as1 link set as1-as2 up
ip -n pocket-as1 link set as1-as4 up
ip -n pocket-as2 link set as2-as1 up
ip -n pocket-as2 link set as2-underlay up
ip -n pocket-as3 link set as3-underlay up
ip -n pocket-as3 link set as3-as4 up
ip -n pocket-as4 link set as4-as3 up
ip -n pocket-as4 link set as4-as1 up
```

Prove the underlay works:

```sh
ip -n pocket-as2 route get 192.0.2.2
ip netns exec pocket-as2 ping -c 1 -W 1 192.0.2.2
```

If this fails, WireGuard has nowhere to send encrypted packets.

## Step 5: Generate WireGuard Keys

Each side gets a private key and a public key:

```sh title="Generate WireGuard private and public keys from the root Linux shell"
( umask 077; wg genkey > /tmp/pocket-internet-wireguard-link/as2.key )
wg pubkey < /tmp/pocket-internet-wireguard-link/as2.key > /tmp/pocket-internet-wireguard-link/as2.pub

( umask 077; wg genkey > /tmp/pocket-internet-wireguard-link/as3.key )
wg pubkey < /tmp/pocket-internet-wireguard-link/as3.key > /tmp/pocket-internet-wireguard-link/as3.pub
```

Print only public keys:

```sh
cat /tmp/pocket-internet-wireguard-link/as2.pub
cat /tmp/pocket-internet-wireguard-link/as3.pub
```

Private keys stay local. Public keys are what peers exchange.

The parentheses keep the stricter `umask` scoped to each private-key command. That makes the private key files readable only by their owner without changing the file permissions for everything else you create in the same shell.

## Step 6: Create WireGuard Overlay Interfaces

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

This reuses the familiar AS2-AS3 link prefix from the earlier labs. The difference is the interface carrying it.

## Step 7: Configure WireGuard Peers

Set shell variables for the public keys:

```sh title="Read WireGuard public keys into shell variables"
AS2_PUB="$(cat /tmp/pocket-internet-wireguard-link/as2.pub)"
AS3_PUB="$(cat /tmp/pocket-internet-wireguard-link/as3.pub)"
```

Configure AS2:

```sh title="Configure the AS2 WireGuard peer"
ip netns exec pocket-as2 wg set wg23 \
  private-key /tmp/pocket-internet-wireguard-link/as2.key \
  listen-port 51823 \
  peer "$AS3_PUB" \
  allowed-ips 10.42.23.2/32,172.20.3.1/32,172.20.4.1/32 \
  endpoint 192.0.2.2:51824
```

Configure AS3:

```sh title="Configure the AS3 WireGuard peer"
ip netns exec pocket-as3 wg set wg23 \
  private-key /tmp/pocket-internet-wireguard-link/as3.key \
  listen-port 51824 \
  peer "$AS2_PUB" \
  allowed-ips 10.42.23.1/32,172.20.1.1/32,172.20.2.1/32 \
  endpoint 192.0.2.1:51823
```

Bring both interfaces up:

```sh
ip -n pocket-as2 link set wg23 up
ip -n pocket-as3 link set wg23 up
```

The `endpoint` is the underlay address and UDP port. The `allowed-ips` list is WireGuard's peer-selection rule for inner packets.

That is why AS2 allows `172.20.3.1/32`: when AS2 forwards a packet toward AS3's service loopback, the inner destination is `172.20.3.1`, not merely `10.42.23.2`.

Read the `AllowedIPs` lists this way:

| Namespace | Peer represents | Inner destinations allowed through that peer |
| --- | --- | --- |
| `pocket-as2` | AS3's side of the tunnel | `10.42.23.2/32`, `172.20.3.1/32`, `172.20.4.1/32` |
| `pocket-as3` | AS2's side of the tunnel | `10.42.23.1/32`, `172.20.1.1/32`, `172.20.2.1/32` |

This does not create BGP routes. BGP still learns reachability and installs routes. WireGuard decides which peer may carry an already-routed inner packet once Linux chooses `wg23`.

That statement is specific to this raw `wg set` lab. Later tools such as `wg-quick`, and many real peer examples, may also install routes from `AllowedIPs`. Here, BGP and the kernel routing table remain separate from WireGuard's peer-selection rule so you can see each layer clearly.

## Step 8: Verify The Overlay Link

Compare the two route lookups from AS2:

```sh title="Compare AS2 underlay and overlay route lookups"
ip -n pocket-as2 route get 192.0.2.2
ip -n pocket-as2 route get 10.42.23.2
```

The first lookup is the underlay endpoint. It should use `as2-underlay`.

The second lookup is the overlay neighbor. It should use `wg23`.

Ask Linux how AS2 reaches the overlay neighbor again if you want to isolate just that result:

```sh
ip -n pocket-as2 route get 10.42.23.2
```

Expected output uses `wg23`.

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

A handshake says the peers have exchanged WireGuard setup traffic. The transfer counters should increase after ping or routed traffic.

## Step 9: Start BIRD Over The New Link

Use the same BIRD pattern as the BGP chapter, with one change: AS2 and AS3 now peer over `wg23` addresses:

```text
pocket-as2 -> pocket-as3
10.42.23.1 -> 10.42.23.2
```

The important point for this chapter is that BIRD does not need to know the link is encrypted. It sees a local interface and a neighbor address.

Read the AS2-to-AS3 shape before writing the full configs:

```text title="Read the BGP-over-WireGuard config shape"
protocol bgp to_as3 {                 # (1)
  local as 4242420002;                # (2)
  neighbor 10.42.23.2 as 4242420003;  # (3)
  source address 10.42.23.1;          # (4)
  check link yes;
  ipv4 {
    import filter pocket_import;      # (5)
    export filter pocket_export;      # (6)
  };
}
```

1. This is AS2's BGP session toward AS3.
2. AS2 uses its own local AS number.
3. AS3's neighbor address is the overlay address on AS3's `wg23`.
4. AS2's source address is the overlay address on AS2's `wg23`.
5. Import policy still controls which routes AS2 accepts.
6. Export policy still controls which routes AS2 announces.

Write the AS1 config:

```sh title="Write /tmp/pocket-internet-wireguard-link/pocket-as1.conf"
cat >/tmp/pocket-internet-wireguard-link/pocket-as1.conf <<'EOF'
log stderr all;
router id 172.20.1.1;

protocol device {
  scan time 1;
}

protocol direct direct_loopbacks {
  ipv4;
  interface "lo";
}

protocol kernel kernel_ipv4 {
  ipv4 {
    import none;
    export all;
  };
  scan time 1;
}

filter pocket_import {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

filter pocket_export {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

protocol bgp to_as2 {
  local as 4242420001;
  neighbor 10.42.12.2 as 4242420002;
  source address 10.42.12.1;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}

protocol bgp to_as4 {
  local as 4242420001;
  neighbor 10.42.41.1 as 4242420004;
  source address 10.42.41.2;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}
EOF
```

Write the AS2 config:

```sh title="Write /tmp/pocket-internet-wireguard-link/pocket-as2.conf"
cat >/tmp/pocket-internet-wireguard-link/pocket-as2.conf <<'EOF'
log stderr all;
router id 172.20.2.1;

protocol device {
  scan time 1;
}

protocol direct direct_loopbacks {
  ipv4;
  interface "lo";
}

protocol kernel kernel_ipv4 {
  ipv4 {
    import none;
    export all;
  };
  scan time 1;
}

filter pocket_import {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

filter pocket_export {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

protocol bgp to_as1 {
  local as 4242420002;
  neighbor 10.42.12.1 as 4242420001;
  source address 10.42.12.2;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}

protocol bgp to_as3 {
  local as 4242420002;
  neighbor 10.42.23.2 as 4242420003;
  source address 10.42.23.1;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}
EOF
```

The `to_as3` neighbor is the important change. AS2 peers with AS3 at `10.42.23.2`, which lives on AS3's `wg23` interface.

Write the AS3 config:

```sh title="Write /tmp/pocket-internet-wireguard-link/pocket-as3.conf"
cat >/tmp/pocket-internet-wireguard-link/pocket-as3.conf <<'EOF'
log stderr all;
router id 172.20.3.1;

protocol device {
  scan time 1;
}

protocol direct direct_loopbacks {
  ipv4;
  interface "lo";
}

protocol kernel kernel_ipv4 {
  ipv4 {
    import none;
    export all;
  };
  scan time 1;
}

filter pocket_import {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

filter pocket_export {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

protocol bgp to_as2 {
  local as 4242420003;
  neighbor 10.42.23.1 as 4242420002;
  source address 10.42.23.2;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}

protocol bgp to_as4 {
  local as 4242420003;
  neighbor 10.42.34.2 as 4242420004;
  source address 10.42.34.1;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}
EOF
```

AS3's `to_as2` block is the matching half of the WireGuard BGP session.

Write the AS4 config:

```sh title="Write /tmp/pocket-internet-wireguard-link/pocket-as4.conf"
cat >/tmp/pocket-internet-wireguard-link/pocket-as4.conf <<'EOF'
log stderr all;
router id 172.20.4.1;

protocol device {
  scan time 1;
}

protocol direct direct_loopbacks {
  ipv4;
  interface "lo";
}

protocol kernel kernel_ipv4 {
  ipv4 {
    import none;
    export all;
  };
  scan time 1;
}

filter pocket_import {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

filter pocket_export {
  if net = 172.20.1.1/32 then accept;
  if net = 172.20.2.1/32 then accept;
  if net = 172.20.3.1/32 then accept;
  if net = 172.20.4.1/32 then accept;
  reject;
}

protocol bgp to_as3 {
  local as 4242420004;
  neighbor 10.42.34.1 as 4242420003;
  source address 10.42.34.2;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}

protocol bgp to_as1 {
  local as 4242420004;
  neighbor 10.42.41.2 as 4242420001;
  source address 10.42.41.1;
  check link yes;
  ipv4 {
    import filter pocket_import;
    export filter pocket_export;
  };
}
EOF
```

Validate the configs before starting BIRD:

```sh title="Validate BIRD configs from the root Linux shell"
bird -p -c /tmp/pocket-internet-wireguard-link/pocket-as1.conf
bird -p -c /tmp/pocket-internet-wireguard-link/pocket-as2.conf
bird -p -c /tmp/pocket-internet-wireguard-link/pocket-as3.conf
bird -p -c /tmp/pocket-internet-wireguard-link/pocket-as4.conf
```

Start BIRD in each namespace:

```sh title="Start BIRD in all four namespaces"
ip netns exec pocket-as1 bird \
  -c /tmp/pocket-internet-wireguard-link/pocket-as1.conf \
  -s /tmp/pocket-internet-wireguard-link/pocket-as1.ctl \
  -P /tmp/pocket-internet-wireguard-link/pocket-as1.pid

ip netns exec pocket-as2 bird \
  -c /tmp/pocket-internet-wireguard-link/pocket-as2.conf \
  -s /tmp/pocket-internet-wireguard-link/pocket-as2.ctl \
  -P /tmp/pocket-internet-wireguard-link/pocket-as2.pid

ip netns exec pocket-as3 bird \
  -c /tmp/pocket-internet-wireguard-link/pocket-as3.conf \
  -s /tmp/pocket-internet-wireguard-link/pocket-as3.ctl \
  -P /tmp/pocket-internet-wireguard-link/pocket-as3.pid

ip netns exec pocket-as4 bird \
  -c /tmp/pocket-internet-wireguard-link/pocket-as4.conf \
  -s /tmp/pocket-internet-wireguard-link/pocket-as4.ctl \
  -P /tmp/pocket-internet-wireguard-link/pocket-as4.pid
```

After BIRD starts, verify the AS2-AS3 BGP session:

```sh title="Inspect BGP protocols across the WireGuard link"
ip netns exec pocket-as2 birdc -s /tmp/pocket-internet-wireguard-link/pocket-as2.ctl show protocols
ip netns exec pocket-as3 birdc -s /tmp/pocket-internet-wireguard-link/pocket-as3.ctl show protocols
```

Expected observation:

```text
to_as3  BGP  ...  Established
to_as2  BGP  ...  Established
```

If those sessions establish, BGP is running over WireGuard.

## Step 10: Prove Existing Routing Still Works

From AS1, ask how to reach AS3's service loopback:

```sh title="Check service-loopback route from pocket-as1"
ip -n pocket-as1 route get 172.20.3.1 from 172.20.1.1
```

At AS2, the path should cross `wg23`:

```sh title="Check that AS2 crosses wg23 toward AS3"
ip -n pocket-as2 route get 172.20.3.1 from 172.20.2.1
```

Expected output includes:

```text
via 10.42.23.2 dev wg23
```

Check the return path from AS3:

```sh title="Check the return path from pocket-as3"
ip -n pocket-as3 route get 172.20.1.1 from 172.20.3.1
```

In the validated transcript, AS3 also chooses the WireGuard side:

```text
via 10.42.23.1 dev wg23
```

The important habit is the check itself. In this four-router ring, AS3 may have more than one BGP-learned way back to AS1. If your output points through AS4 instead, do not treat that as a WireGuard failure by itself. AS2's route to `172.20.3.1`, the successful AS1-to-AS3 ping, and the WireGuard transfer counters are the evidence that the replaced AS2-AS3 link is carrying traffic.

Now test traffic:

```sh
ip netns exec pocket-as1 ping -c 2 -W 1 -I 172.20.1.1 172.20.3.1
```

Finally, inspect WireGuard counters again:

```sh title="Inspect WireGuard state inside pocket-as2"
ip netns exec pocket-as2 wg show wg23
```

The transfer counters should be larger than before. That is evidence that Pocket Internet traffic crossed the WireGuard link.

## Troubleshooting Branches

### Underlay Fails

If this fails:

```sh
ip netns exec pocket-as2 ping -c 1 -W 1 192.0.2.2
```

fix the underlay before changing WireGuard. The tunnel cannot work if its carrier path is broken.

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

### Handshake Works But BGP Fails

Check overlay reachability:

```sh
ip netns exec pocket-as2 ping -c 1 -W 1 10.42.23.2
ip netns exec pocket-as3 ping -c 1 -W 1 10.42.23.1
```

If overlay ping works, inspect BIRD:

```sh title="Inspect the detailed AS2 to AS3 BGP session"
ip netns exec pocket-as2 birdc -s /tmp/pocket-internet-wireguard-link/pocket-as2.ctl show protocols all to_as3
```

### BGP Works But Service Prefix Traffic Fails

Check WireGuard `AllowedIPs`.

If AS2 will forward packets to `172.20.3.1`, AS2's WireGuard peer for AS3 must allow `172.20.3.1/32`.

This is different from BGP import/export policy. BGP decides which routes are learned. WireGuard decides which peer is allowed to carry matching inner packets.

## Rollback

Stop lab BIRD processes if they are still running:

```sh
for ns in pocket-as1 pocket-as2 pocket-as3 pocket-as4; do
  if [ -f "/tmp/pocket-internet-wireguard-link/${ns}.pid" ]; then
    ip netns exec "$ns" kill "$(cat "/tmp/pocket-internet-wireguard-link/${ns}.pid")" 2>/dev/null || true
  fi
done
```

Delete namespaces and generated files:

```sh
ip netns delete pocket-as1 2>/dev/null || true
ip netns delete pocket-as2 2>/dev/null || true
ip netns delete pocket-as3 2>/dev/null || true
ip netns delete pocket-as4 2>/dev/null || true
rm -rf /tmp/pocket-internet-wireguard-link
```

Prove cleanup worked:

```sh
if ip netns list | grep -E '^(pocket-as1|pocket-as2|pocket-as3|pocket-as4)( |$)'; then
  echo 'leftover Pocket Internet namespaces found'
  exit 1
fi
echo 'no Pocket Internet namespaces remain'
```

Confirm the public default path still uses the normal host route:

```sh
ip route get 1.1.1.1
```

## What You Can Now Explain

You can now explain:

- the difference between an underlay and an overlay,
- why WireGuard needs keys and endpoints,
- why a handshake is necessary but not enough to prove routed traffic works,
- why `AllowedIPs` must include inner destinations carried by the tunnel,
- how BGP can run over a WireGuard interface the same way it ran over veth,
- why this is still Pocket Internet work, not DN42 peering.

## Still Okay If Fuzzy

It is okay if these are still fuzzy:

- MTU sizing,
- NAT traversal and persistent keepalive,
- `wg-quick`,
- host-to-lab access,
- real DN42 peer expectations.

Those belong in later border and DN42 chapters. Here, the point is narrower: a tunnel can replace a link without changing the routing mental model.

## Next We Need

At this point, the Pocket Internet draft is functionally complete:

- hosts and routers,
- static routes,
- route selection,
- BIRD and BGP,
- services,
- WireGuard as a link.

The next phase is cleanup and then the DN42 border: how a lab-built routing model approaches a living routing community without leaking routes or treating DN42 as a sandbox.

## References

- `wireguard-quickstart`
- `wireguard-netns`
