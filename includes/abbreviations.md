*[address]: One specific point in the IP address space, usually assigned to an interface or loopback.
*[address space]: The full set of addresses that can exist in an IP version or prefix.
*[application traffic]: Traffic for a real program instead of a routing probe such as ping.
*[AllowedIPs]: WireGuard's peer-selection and packet-allow list for tunnel traffic. Some tools also use it to install routes.
*[autonomous system]: One independently controlled network boundary. In real Internet routing, an autonomous system is identified by an ASN.
*[bind address]: The local address a service attaches to when it starts listening.
*[BGP]: Border Gateway Protocol. Routers use BGP to exchange network reachability with other routers.
*[BIRD]: A routing daemon that can learn, select, filter, and install routes.
*[convergence]: The network settling on usable routes after a routing change or failure.
*[connected route]: A route Linux creates automatically for a prefix assigned directly to an interface.
*[default route]: The fallback route used when no more-specific route matches. In IPv4 it is also written as `0.0.0.0/0`.
*[DN42]: A community overlay network used for learning and experimenting with routing, DNS, and network services.
*[export filter]: A rule that decides which routes a router announces to a neighbor.
*[endpoint]: The underlay address and UDP port where a WireGuard peer receives tunnel packets.
*[forwarding]: Receiving a packet that is not addressed to this machine and sending it onward according to the route table.
*[host route]: A route for exactly one IP address, such as `172.20.30.42/32`.
*[handshake]: Evidence that WireGuard peers exchanged setup traffic.
*[HTTP]: A simple request/response protocol used by web clients and servers.
*[import filter]: A rule that decides which routes a router accepts from a neighbor.
*[inner packet]: The packet the overlay network thinks it is sending before a tunnel wraps it.
*[interface]: A place where packets enter or leave a network stack.
*[listener]: The address and port where a service waits for connections.
*[longest-prefix match]: The route lookup rule that the most-specific matching route wins.
*[loopback]: The `lo` interface inside a network stack; traffic sent to loopback stays inside that stack.
*[network namespace]: An isolated Linux network stack with its own interfaces, addresses, and routes.
*[network stack]: The part of an operating system that owns interfaces, addresses, routes, and packet handling.
*[next hop]: The next router a packet should be sent to.
*[on-link]: Reachable through a local interface without first sending the packet to another IP router.
*[overlay]: The logical network carried by an underlay.
*[outer packet]: The packet that carries a tunneled inner packet across the underlay.
*[port]: A number identifying a service on an address.
*[prefix]: A group of IP addresses written as a starting address plus a prefix length.
*[prefix length]: The number after `/`; a larger number means a smaller, more-specific prefix.
*[private key]: A secret key that stays local.
*[public key]: A key that can be shared with a peer.
*[return path]: The route a reply packet uses to get back to the original sender.
*[route]: An instruction that tells Linux where to send packets for a destination.
*[route advertisement]: Telling another router that you can carry traffic for a prefix.
*[route leak]: Accidentally announcing or accepting routes that should not cross a routing boundary.
*[route lookup]: Asking Linux which route it would use for a packet.
*[route table]: The list of routes Linux uses when deciding where to send packets.
*[service]: A program that listens for network connections and responds.
*[service loopback]: A stable address on `lo` that represents a service or prefix a router could advertise later.
*[static route]: A route written by hand.
*[tunnel]: A logical link carried inside another network path.
*[underlay]: The network that carries an overlay tunnel.
*[veth pair]: A virtual Ethernet cable with two ends. A packet sent into one end comes out the other.
*[VPN]: A tool that creates a private-looking network path across another network.
*[WireGuard]: A VPN protocol commonly used to create encrypted tunnel links.
