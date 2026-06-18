# Glossary

Tooltip definitions for recurring terms live in `includes/abbreviations.md`. Keep this page and that file aligned when introducing new beginner-facing terms.

For the beginner-facing map of Linux objects, see [Linux Networking Objects](linux-networking-objects.md).

ASN
: Autonomous System Number. A number identifying a routing domain in BGP.

Application traffic
: Traffic for a real program instead of a routing probe such as ping.

Bind address
: The local address a service attaches to when it starts listening.

BGP
: Border Gateway Protocol. The inter-domain routing protocol used to exchange reachability information between autonomous systems.

BIRD
: A routing daemon commonly used in DN42 labs and deployments.

Convergence
: The network settling on usable routes after a routing change or failure.

DN42
: A community overlay network used for learning and experimenting with routing, DNS, and network services.

HTTP
: A simple request/response protocol used by web clients and servers.

Listener
: The address and port where a service waits for connections.

Port
: A number identifying a service on an address.

Service
: A program that listens for network connections and responds.

FIB
: Forwarding Information Base. The forwarding table used by the data plane.

RIB
: Routing Information Base. The set of routes known to a routing process before final forwarding installation.

ROA
: Route Origin Authorization. In public RPKI, a cryptographic authorization that an ASN may originate a prefix. DN42 has registry-derived origin validation concepts that must not be described as identical to public RPKI.

ULA
: Unique Local Address. IPv6 private addressing defined by RFC 4193.

WireGuard
: A VPN protocol commonly used to create DN42 tunnel links over the public Internet.
