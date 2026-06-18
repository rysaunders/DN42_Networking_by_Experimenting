# First BIRD Session

!!! warning "Later draft - not implementation-ready"
    This page is roadmap material. Current DN42 BIRD 2 practice, registry-derived validation, import filters, and export filters must be refreshed before release.

## Concept

BIRD establishes a BGP session with the DN42 peer and applies import/export policy.

## Why It Matters

The first BGP session is where reachability becomes shared network state. Safe filters matter before the session is enabled.

## Lab / Experiment

Draft: configure one BIRD 2 BGP protocol with conservative import and export filters.

## Expected Observations

- The peer reaches Established.
- Imported routes are visible in BIRD.
- Only authorized local prefixes are exported.

## Troubleshooting Notes

- Active or Connect state points to transport, address, ASN, or firewall issues.
- Established with no routes points to policy or validation.
- Unexpected exports mean stop and fix filters before proceeding.

## How the Real Internet Does This

External BGP is policy-driven. Real operators define what they accept, prefer, reject, and announce.

## References

- `bird-docs`
- `rfc-4271`
- `dn42-getting-started`
