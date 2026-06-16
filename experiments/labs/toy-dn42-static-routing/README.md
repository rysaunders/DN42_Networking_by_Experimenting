# Toy DN42 Static Routing Lab

This lab builds a disposable four-AS Toy DN42 topology with Linux network namespaces:

- `toy-as1`
- `toy-as2`
- `toy-as3`
- `toy-as4`

The namespaces form a square. Each namespace has point-to-point veth links, a loopback service address, forwarding enabled, and static routes for remote service addresses.

The lab demonstrates:

- AS-shaped namespaces,
- veth links as local point-to-point links,
- loopback addresses as stable service addresses,
- static route lookup across multiple hops,
- end-to-end ping between service addresses,
- packet counter evidence on transit links,
- link failure with no automatic reroute,
- manual route repair through the alternate path,
- rollback that removes namespaces and veth state.

## Before Running

- Linux is required because this lab uses Linux network namespaces.
- `iproute2` is required for the `ip` command.
- Root privileges are required; the script uses `sudo` when it is not already running as root.
- macOS users should run the lab inside an OrbStack Linux machine.
- The transcript is written under `experiments/transcripts/`.

Run from the repository root on a Linux host or OrbStack Linux machine:

```sh
bash experiments/labs/toy-dn42-static-routing/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/toy-dn42-static-routing/run.sh
```

The script uses `sudo` for namespace operations when it is not already running as root. It writes a transcript to `experiments/transcripts/`.
