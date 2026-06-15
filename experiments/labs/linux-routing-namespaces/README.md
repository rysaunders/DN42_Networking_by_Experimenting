# Linux Routing Namespaces Lab

This lab builds a disposable three-node IPv4 network with Linux network namespaces:

- `dn42lab-left`
- `dn42lab-router`
- `dn42lab-right`

The middle namespace forwards traffic between the two edge namespaces. The lab demonstrates:

- isolated namespace setup,
- route lookup before packet forwarding,
- forwarding through a Linux router namespace,
- rollback that removes namespaces and veth state.

Run from the repository root on a Linux host or OrbStack Linux machine:

```sh
bash experiments/labs/linux-routing-namespaces/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/linux-routing-namespaces/run.sh
```

The script uses `sudo` for namespace operations when it is not already running as root. It writes a transcript to `experiments/transcripts/`.
