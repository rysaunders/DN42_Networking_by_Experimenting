# Pocket Internet Linux Router Lab

This lab builds a disposable three-node IPv4 network with Linux network namespaces:

- `pocket-left`
- `pocket-router`
- `pocket-right`

The middle namespace forwards traffic between the two edge namespaces. The lab demonstrates:

- isolated namespace setup,
- route lookup before packet forwarding,
- the difference between having a route and having forwarding enabled,
- forwarding through a Linux router namespace,
- rollback that removes namespaces and veth state.

## Before Running

- Linux is required because this lab uses Linux network namespaces.
- `iproute2` is required for the `ip` command.
- Root privileges are required to create namespaces and veth interfaces.
- The script uses `sudo` when it is not already running as root.
- macOS users should run the lab inside an OrbStack Linux machine.
- The transcript is written under ignored `experiments/transcripts/local/` by default.

Run from the repository root on a Linux host or OrbStack Linux machine:

```sh
bash experiments/labs/pocket-internet-linux-router/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/pocket-internet-linux-router/run.sh
```
