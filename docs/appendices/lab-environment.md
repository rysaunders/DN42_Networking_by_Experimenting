# Lab Environment

The initial labs should be developed against disposable local environments before touching public DN42 state.

Preferred early environments:

- Linux network namespaces for first-principles routing.
- Local WireGuard peers between namespaces.
- Local BIRD-to-BIRD sessions between namespaces.

The published labs should record:

- distribution,
- kernel version,
- `iproute2` version,
- WireGuard tooling version,
- BIRD version,
- resolver implementation,
- firewall tool.

Environment-specific behavior should be marked clearly.
