# Later: First DN42 Node

!!! warning "Later draft - not implementation-ready"
    This section is roadmap material, not a complete DN42 setup guide. Current-practice claims must be refreshed against DN42 sources before publication, and no command sequence here should be treated as production-ready until the chapter is explicitly validated.

These chapters are later-phase drafts. They should follow the Pocket Internet foundation and the Pocket Internet to DN42 border design.

The goal is still one safe public DN42 peer, but the reader should reach it after they can explain local route lookup, return path, WireGuard-as-link, BIRD, BGP, and export policy in the lab.

By the end of this part, the reader should have:

- Built the Pocket Internet foundation.
- Designed the DN42 border.
- Registered required DN42 objects.
- Configured one WireGuard peer.
- Established one BIRD session.
- Installed accepted routes into the Linux kernel.
- Configured split DNS for `.dn42`.
- Reached one DN42 service.

Current-practice claims in this part must be refreshed before release.
