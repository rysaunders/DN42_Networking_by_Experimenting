# DN42 DNS

!!! warning "Later draft - not implementation-ready"
    This page is roadmap material. Current DN42 DNS resolver recommendations and resolver-specific behavior must be refreshed before release.

    Before this becomes an implementation chapter, it must satisfy the [mandatory border checklist](../pocket-internet-dn42-interconnect.md#mandatory-border-checklist).

## Concept

Split DNS lets `.dn42` names resolve through DN42-aware resolvers while normal public DNS continues to work normally.

## Why It Matters

Routing may work while names fail. DNS configuration should be tested separately from packet forwarding.

## Lab / Experiment

Draft: configure a resolver path for `.dn42` and prove public DNS still uses the normal resolver path.

## Expected Observations

- `.dn42` queries reach the intended resolver.
- Public domains still resolve normally.
- DNS changes do not create a default route through DN42.

## Troubleshooting Notes

- Resolver routing domains differ by resolver implementation.
- Caches can preserve old failures.
- DNSSEC behavior may differ between public and DN42 names.

## How the Real Internet Does This

The public DNS relies on delegation from the root. Split DNS deliberately routes some names through a different resolver path.

## References

- `dn42-getting-started`
