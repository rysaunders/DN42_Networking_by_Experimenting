# Part 1: Pocket Internet Foundations

??? info "Maintainer metadata"
    ```yaml
    chapter_id: part-01-index
    status: published-overview
    safety_level: conceptual
    lab_id: none
    depends_on:
      - pocket-internet-overview
    transcript: none
    source_ids: []
    tested_environment:
      host: not applicable
      distro: not applicable
      kernel: not applicable
      bird: not used
      wireguard_tools: not used
    beginner_review:
      status: deferred
      note: Overview page; no formal beginner review record for this metadata pass.
    technical_review:
      required: false
      status: not_required
      note: Conceptual section index; no commands or real-network procedure.
    ```

Part 1 builds the local model for Pocket Internet before any public DN42 state enters the picture.

!!! note "IPv4-only foundation"
    Most Part 1 labs use IPv4 examples so the first route-lookup, forwarding, BIRD, BGP, and WireGuard labs stay observable. The IPv6 and ULA foundation chapter then introduces the address-family differences before production-shaped DN42 chapters rely on them.

By the end of this part, the reader should be able to:

- Predict which interface a packet will leave.
- Explain basic source address selection.
- Read route tables and identify connected, default, and BGP-learned routes.
- Explain why explicit routes matter before dynamic routing is introduced.
- Explain why BIRD and BGP are useful after static routes become tedious.
- Operate a simple service inside the lab.
- Explain how a WireGuard tunnel can behave like a point-to-point link.
- Observe local-link discovery and packet movement without confusing those checks for full application success.
- Explain the first IPv6/ULA routing differences before real DN42 examples appear.

The labs are local and disposable. They start with Linux routing, then add BIRD, BGP, services, WireGuard, operational observation, and a first IPv6/ULA pass before any public DN42 state enters the picture.

Chapter 05 teaches BIRD as a local route manager before Chapter 06 asks it to speak BGP. That sequence matters: first BIRD learns and exports routes locally, then BIRD exchanges reachability with other routers.
