# Internet Readiness Standard

Pocket Internet is the lab frame. It is not the whole subject.

The book's job is to make unapproachable Internet networking concepts approachable enough that a reader can eventually touch DN42 or real public routing without treating commands as magic.

That means a working lab is necessary but not sufficient.

## Editorial Position

Treat every proposed chapter, lab, or restructuring idea as a hypothesis.

Do not accept an idea only because it fits the current Pocket Internet shape. Ask whether it improves the reader's future ability to reason about a real network.

The standing question remains:

> How does an Internet emerge from a collection of computers exchanging routes?

But every chapter also needs a second check:

> What would still make this reader lost, unsafe, or overconfident on DN42 or the public Internet?

## Three Anchors

Use these anchors when drafting, reviewing, or revising content.

### Beginner Reality

Can a reader explain what happened, not just run the command?

Check for:

- undefined terms,
- hidden state between commands,
- commands that succeed without a mental model,
- diagrams missing where topology or packet flow is hard to hold in memory,
- evidence that is easy to overread.

### Technical Truth

Are we teaching how the system actually behaves?

Check for:

- tested command output,
- clear separation between Linux, BIRD, WireGuard, DNS, and application behavior,
- lab-only shortcuts called out as lab-only,
- volatile DN42 or public-routing claims tied to current sources,
- simplifications named as simplifications.

### Operational Readiness

Would this help the reader avoid dangerous mistakes when touching a real network?

Check for:

- route leaks,
- default-route accidents,
- unauthorized prefix advertisement,
- missing return path,
- source-address confusion,
- firewall or filtering gaps,
- monitoring and rollback gaps,
- public Internet versus DN42 versus local lab boundaries.

## Required Chapter Questions

Every substantive chapter should answer these questions, either explicitly in prose or implicitly through clear structure:

1. What Internet concept does this teach?
2. What can the reader do after this chapter that they could not do before?
3. What dangerous misconception might the lab accidentally create?
4. What is still not taught that would matter on DN42 or the public Internet?

If the answer to question 4 includes major missing areas such as DNS, TCP/UDP, sockets, TLS, NAT, firewalls, IPv6, route policy, abuse handling, monitoring, or operational rollback, name that gap instead of smoothing it over.

## Lab Scope Rule

A lab can be narrow. The explanation cannot pretend the narrow lab is complete.

For example:

- A successful `ping` proves packet reachability for that ICMP test, not service reachability.
- A `wg show` handshake proves WireGuard peer setup traffic, not BGP convergence.
- A BIRD route proves control-plane state, not kernel forwarding until Linux route state is inspected.
- A lab ASN or prefix teaches shape, not authorization.
- A local namespace lab teaches Linux behavior, not all router platforms.

Use evidence callouts when a command result is easy to overread.

## Coverage Pressure

Pocket Internet currently emphasizes Linux routing, BIRD, BGP, and WireGuard. That is a useful spine, but it must not become a tunnel.

Future planning and audits should watch for delayed or missing coverage of:

- DNS and naming,
- TCP, UDP, ports, sockets, and listeners,
- TLS and service identity,
- firewalls and packet filtering,
- NAT and source-address translation,
- IPv6 and ULA,
- ARP/NDP and local-link discovery,
- MTU and fragmentation,
- route policy, filtering, and authorization,
- observability, logs, metrics, packet captures, and looking glasses,
- abuse, exposure, and operational responsibility.

Not every topic belongs early. But if the reader would be unsafe or badly confused without it, the roadmap should say where it will be taught.

## Review Addendum

Beginner review asks whether the reader can follow the chapter.

Internet-readiness review asks whether the chapter moves the reader toward competent real-network reasoning.

For substantive new content, the reviewer should also ask:

- Does this chapter reduce or increase false confidence?
- Does it clearly label lab-only behavior?
- Does it distinguish packet movement, service behavior, routing control plane, and policy?
- Does it say what the reader is still not ready to do?
- Would a reader who completed this chapter still be lost at the DN42/public-network boundary? If so, what exact gap remains?

## Backward Audit Rule

When this standard is added or changed, create a follow-up audit issue for existing chapters.

The audit should not become an unbounded rewrite. It should produce:

- accepted quick fixes,
- deferred follow-up issues,
- explicit decisions that a gap belongs in a later chapter.
