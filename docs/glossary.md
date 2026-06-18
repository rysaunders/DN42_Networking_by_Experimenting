# Glossary

Tooltip definitions for recurring terms live in `includes/abbreviations.md`. Keep this page and that file aligned when introducing new beginner-facing terms.

For the beginner-facing map of Linux objects, see [Linux Networking Objects](linux-networking-objects.md).

ASN
: Autonomous System Number. A number identifying a routing domain in BGP.

Application traffic
: Traffic for a real program instead of a routing probe such as ping.

AllowedIPs
: WireGuard's peer-selection and packet-allow list for tunnel traffic. In `wg-quick` and some real peer examples, AllowedIPs may also be used to install routes.

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

Endpoint
: The underlay address and UDP port where a WireGuard peer receives tunnel packets.

Handshake
: Evidence that WireGuard peers exchanged setup traffic.

HTTP
: A simple request/response protocol used by web clients and servers.

Inner packet
: The packet the overlay network thinks it is sending before a tunnel wraps it.

Listener
: The address and port where a service waits for connections.

Overlay
: The logical network carried by an underlay.

Outer packet
: The packet that carries a tunneled inner packet across the underlay.

Port
: A number identifying a service on an address.

Private key
: A secret key that stays local.

Public key
: A key that can be shared with a peer.

Service
: A program that listens for network connections and responds.

Tunnel
: A logical link carried inside another network path.

VPN
: A tool that creates a private-looking network path across another network.

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
