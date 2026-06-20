# Glossary

This page is the comprehensive vocabulary reference. Global tooltip definitions live in `includes/abbreviations.md`, but that file is intentionally sparse so normal prose does not become visually noisy.

When introducing a new term, add it here by default. Add it to global tooltips only when it is a high-value recurring reminder, acronym, tool/protocol name, safety concept, or easy-to-confuse idea.

For the beginner-facing map of Linux objects, see [Linux Networking Objects](linux-networking-objects.md).

ASN
: Autonomous System Number. A number identifying a routing domain in BGP. Lab ASNs are local labels until a real network or registry authorizes their use.

Address
: One specific point in the IP address space, usually assigned to an interface or loopback.

Address space
: The full set of addresses that can exist in an IP version or prefix.

Application traffic
: Traffic for a real program instead of a routing probe such as ping.

AllowedIPs
: WireGuard's peer-selection and packet-allow list for tunnel traffic. In `wg-quick` and some real peer examples, AllowedIPs may also be used to install routes.

Autonomous system
: One independently controlled network boundary. In real Internet routing, an autonomous system is identified by an ASN.

Authorized prefix
: An address block a network is allowed to originate or announce. In DN42-facing chapters, authorization must come from the relevant registry objects and peer expectations, not from a lab example.

Asymmetric routing
: A path shape where request traffic and reply traffic do not use the same routers or links.

Bind address
: The local address a service attaches to when it starts listening.

BGP
: Border Gateway Protocol. The inter-domain routing protocol used to exchange reachability information between autonomous systems.

BIRD
: A routing daemon commonly used in DN42 labs and deployments.

BIRD route table
: BIRD's own set of known and selected routes. It is separate from the Linux route table used for packet forwarding.

Convergence
: The network settling on usable routes after a routing change or failure.

Connected route
: A route Linux creates automatically for a prefix assigned directly to an interface.

Direct protocol
: A BIRD protocol that learns routes from local interfaces.

Default route
: The fallback route used when no more-specific route matches. In IPv4 it is also written as `0.0.0.0/0`.

DN42
: A community overlay network used for learning and experimenting with routing, DNS, and network services.

Endpoint
: The underlay address and UDP port where a WireGuard peer receives tunnel packets.

Export filter
: A rule that decides which routes may leave a BIRD table toward a protocol. In BGP, that usually means deciding which routes to announce to a neighbor. In the kernel protocol, it means deciding which routes BIRD may install into Linux.

Forwarding
: Receiving a packet that is not addressed to this machine and sending it onward according to the route table.

Handshake
: Evidence that WireGuard peers exchanged setup traffic.

Host route
: A route for exactly one IP address, such as `172.20.30.42/32`.

HTTP
: A simple request/response protocol used by web clients and servers.

Import filter
: A rule that decides which routes may enter a BIRD table from a protocol. In BGP, that usually means deciding which received neighbor routes to accept.

Inner packet
: The packet the overlay network thinks it is sending before a tunnel wraps it.

Interface
: A place where packets enter or leave a network stack.

IPv6
: The newer Internet Protocol address family. The current Pocket Internet labs are IPv4-only until IPv6 is intentionally introduced.

Listener
: The address and port where a service waits for connections.

Longest-prefix match
: The route lookup rule that the most-specific matching route wins.

Lab-only prefix
: An address block used only inside the local lab. A lab-only prefix can teach routing behavior, but it is not permission to advertise that route to DN42 or any other external network.

Kernel protocol
: A BIRD protocol that exchanges routes with the Linux kernel route table. In the Pocket Internet labs, it is the boundary where selected BIRD routes can become Linux forwarding routes.

Loopback
: The `lo` interface inside a network stack; traffic sent to loopback stays inside that stack.

Network namespace
: An isolated Linux network stack with its own interfaces, addresses, and routes.

Network stack
: The part of an operating system that owns interfaces, addresses, routes, and packet handling.

MTU
: Maximum Transmission Unit. The largest packet size a link can carry without fragmentation at that layer.

Next hop
: The next router a packet should be sent to.

On-link
: Reachable through a local interface without first sending the packet to another IP router.

Overlay
: The logical network carried by an underlay.

Outer packet
: The packet that carries a tunneled inner packet across the underlay.

Port
: A number identifying a service on an address.

Prefix
: A group of IP addresses written as a starting address plus a prefix length.

Prefix length
: The number after `/`; a larger number means a smaller, more-specific prefix.

Private key
: A secret key that stays local.

Public key
: A key that can be shared with a peer.

Return path
: The route a reply packet uses to get back to the original sender.

Route
: An instruction that tells Linux where to send packets for a destination.

Route advertisement
: Telling another router that you can carry traffic for a prefix.

Route leak
: Accidentally announcing or accepting routes that should not cross a routing boundary, such as sending a lab-only prefix toward DN42 or accepting a route where the chapter expected containment.

Route lookup
: Asking Linux which route it would use for a packet.

Route table
: A list of routes used by a routing component. Linux has route tables for packet forwarding; BIRD has its own route table before selected routes are exported to Linux.

Routing daemon
: A background program that manages routes.

Reverse-path filtering
: A Linux source-validation check, often controlled by `rp_filter`, that can drop packets when the return route does not match what the kernel expects.

Service
: A program that listens for network connections and responds.

Service loopback
: A stable address on `lo` that represents a service or prefix a router could advertise later.

Static route
: A route written by hand.

Static protocol
: A BIRD protocol that creates configured routes inside BIRD.

Tunnel
: A logical link carried inside another network path.

Underlay
: The network that carries an overlay tunnel.

Veth pair
: A virtual Ethernet cable with two ends. A packet sent into one end comes out the other.

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
