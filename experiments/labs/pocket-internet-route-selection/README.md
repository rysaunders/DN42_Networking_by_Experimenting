# Pocket Internet Route Selection

This lab validates the route-selection chapter.

It creates one temporary namespace, `pocket-rs-edge`, with two dummy interfaces:

- `edge-transit0`
- `edge-service0`

The lab installs overlapping routes and uses `ip route get` to prove that the
more-specific route wins. It then removes the more-specific route and shows
fallback to the broader route.

Run from the repository root on Linux:

```sh
bash experiments/labs/pocket-internet-route-selection/run.sh
```

Run from macOS with OrbStack:

```sh
orb bash experiments/labs/pocket-internet-route-selection/run.sh
```
