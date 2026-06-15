# Safety

Safety is part of the curriculum. The labs are meant to teach routing by changing real network state, so each experiment needs clear boundaries and rollback.

## Recurring Warnings

- Do not leak public Internet routes into DN42.
- Do not leak DN42 or private routes to public interfaces.
- Do not announce prefixes you do not own.
- Do not accept a default route from a DN42 peer in beginner labs.
- Do not provide public Internet egress through DN42 unless that is a deliberate and secured service.
- Do not export routes learned from one peer to another until export policy is explicit and reviewed.
- Do not disable host firewalls globally to make a lab pass.
- Do not publish private keys, home IP addresses, or personal contact data by accident.

## Verify Before Proceeding

Use this checklist at the end of every lab:

- [ ] I can identify the underlay public interface and the DN42 overlay interface.
- [ ] `ip route get <dn42-target>` uses the expected DN42 route.
- [ ] `ip route get 1.1.1.1` does not use DN42.
- [ ] BIRD exports only authorized prefixes.
- [ ] BIRD imports only routes accepted by current filters.
- [ ] No default route was learned from DN42 unless the lab explicitly requires it.
- [ ] Firewall rules allow required tunnel and BGP traffic while denying unintended forwarding.
- [ ] Rollback commands are written down and tested.

## Rollback Pattern

Each lab should provide exact commands for its target environment. Until then, the general rollback shape is:

1. Stop the service changed by the lab.
2. Disable the service from boot if the lab enabled it.
3. Bring down temporary tunnel interfaces.
4. Remove temporary route rules and routes.
5. Restore configuration from the lab backup.
6. Confirm normal public Internet routing still uses the normal default route.
7. Confirm no unintended DN42 routes remain in the kernel.
