# Part 1: Pocket Internet Foundations

Part 1 builds the local model for Pocket Internet before any public DN42 state enters the picture.

!!! note "IPv4-only foundation"
    Part 1 uses IPv4 examples so the first route-lookup, forwarding, BIRD, BGP, and WireGuard labs stay observable. This is not the full real-network model. IPv6 and ULA must be taught before production-shaped DN42 chapters rely on them.

By the end of this part, the reader should be able to:

- Predict which interface a packet will leave.
- Explain basic source address selection.
- Read route tables and identify connected, default, and BGP-learned routes.
- Explain why explicit routes matter before dynamic routing is introduced.
- Explain why BIRD and BGP are useful after static routes become tedious.
- Operate a simple service inside the lab.
- Explain how a WireGuard tunnel can behave like a point-to-point link.

The labs are local and disposable. They start with Linux routing, then add BIRD, BGP, services, and WireGuard before any public DN42 state enters the picture.

Chapter 05 teaches BIRD as a local route manager before Chapter 06 asks it to speak BGP. That sequence matters: first BIRD learns and exports routes locally, then BIRD exchanges reachability with other routers.
