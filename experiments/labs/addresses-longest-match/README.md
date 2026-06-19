# Addresses, Prefixes, and Longest Match Lab

This lab creates one disposable Linux network namespace and installs overlapping routes to show longest-prefix match.

Overlapping routes means more than one route could match the same destination. This lab observes which route Linux would choose; it does not build real neighbors behind the fake next hops.

The lab demonstrates:

- an address as one point,
- a prefix as a set of addresses,
- `/16`, `/24`, and `/32` route specificity,
- default route fallback,
- `ip route get` as a prediction tool,
- route fallback after deleting more-specific routes,
- rollback that removes the namespace and temporary routes.

## Before Running

- Linux is required because this lab uses Linux network namespaces.
- `iproute2` is required for the `ip` command.
- Root privileges are required; the script uses `sudo` when it is not already running as root.
- macOS users should run the lab inside an OrbStack Linux machine.
- The transcript is written under ignored `experiments/transcripts/local/` by default.

Run from the repository root on a Linux host or OrbStack Linux machine:

```sh
bash experiments/labs/addresses-longest-match/run.sh
```

On macOS with OrbStack:

```sh
orb bash experiments/labs/addresses-longest-match/run.sh
```
