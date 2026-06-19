# Lab Environment

Pocket Internet labs need a real Linux networking environment. They create network namespaces, virtual links, addresses, routes, and later WireGuard and BIRD state. That does not mean they need a public server, but it does mean a normal macOS shell is not enough.

Run the preflight from the repository root inside Linux before starting the labs:

```sh
./scripts/preflight_lab_env.sh
```

On macOS, use an OrbStack Linux shell first:

```sh
orb
cd /path/to/DN42_Networking_by_Experimenting
./scripts/preflight_lab_env.sh
```

The script creates one disposable namespace, tests the basic capabilities, and removes the namespace before it exits.

## What Preflight Checks

- root, passwordless `sudo`, or enough network capability for namespace tests,
- `ip` and `ip netns`,
- namespace creation,
- loopback inside the namespace,
- dummy interface creation,
- veth pair creation,
- WireGuard interface creation when kernel support is available,
- `wg` when installed,
- BIRD and `birdc` when installed,
- `python3` for service labs,
- cleanup of the disposable namespace.

Warnings are not always blockers. For example, missing BIRD does not block the first static-routing labs, but it will block BIRD/BGP chapters.

## Environment Matrix

| Environment | Expected result | Notes |
| --- | --- | --- |
| OrbStack Linux machine on Apple Silicon | Known good for current labs | Validated with `pocket-internet-lab` on `aarch64`. Install `wireguard-tools` and BIRD 2 before later labs. |
| Native Linux VM with recent kernel | Expected good | Needs root or usable sudo, `iproute2`, WireGuard kernel support, and packages for later labs. |
| Linux laptop or server | Expected good with care | Use a disposable machine when possible. The labs avoid persistent networking changes, but mistakes are easier to reason about in a lab VM. |
| Docker container | Often problematic | Containers commonly lack `CAP_NET_ADMIN`, nested namespace permissions, WireGuard kernel support, or module access. Use only if preflight passes. |
| WSL | Likely problematic | Network namespace and WireGuard behavior depends on WSL version and host integration. Treat as unsupported until preflight passes and a transcript proves it. |
| macOS shell without Linux VM | Not supported | macOS does not provide Linux network namespaces or Linux `ip netns`. Use OrbStack, a Linux VM, or a separate Linux host. |
| Remote VPS | Possible but not first choice | Works if the provider allows needed kernel features. Avoid public DN42 or default-route changes while learning local labs. |

## Recorded Environment Fields

Validated transcripts should record:

- distribution,
- kernel version,
- `iproute2` version,
- WireGuard tooling version,
- BIRD version,
- resolver implementation,
- firewall tool.

Environment-specific behavior should be marked clearly.

## Cleanup Boundary

Preflight and labs should mutate only disposable lab objects:

- namespaces with lab-specific names,
- veth pairs inside those namespaces or attached to them,
- dummy interfaces used for probes,
- WireGuard interfaces inside namespaces,
- temporary files under `/tmp`.

They should not change host default routes, public interfaces, persistent firewall rules, or system services unless a later chapter explicitly says so and provides rollback.
