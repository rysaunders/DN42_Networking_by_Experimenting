# Registry Objects

!!! warning "Later draft - not implementation-ready"
    This page is roadmap material. Current DN42 registry practice must be refreshed before release, and the draft below is not a complete submission procedure.

## Concept

DN42 registry objects describe maintainers, contacts, ASNs, prefixes, routes, and optional DNS delegations.

## Why It Matters

Peers use registry data and derived validation material to decide whether route announcements should be trusted.

## Lab / Experiment

Draft: prepare registry objects locally and run current validation checks before submitting changes.

## Expected Observations

- Maintainer and contact objects identify who can manage resources.
- Prefix and route objects bind resources to an origin ASN.
- Validation catches formatting and policy problems before review.

## Troubleshooting Notes

- Object formatting is strict.
- Authentication and privacy choices matter because registry data is public.
- Route max-length must match the intended announcement policy.

## How the Real Internet Does This

DN42 registry practice resembles parts of RIR and routing registry workflows, but it is community-operated and not identical to public Internet resource management.

## References

- `dn42-getting-started`
