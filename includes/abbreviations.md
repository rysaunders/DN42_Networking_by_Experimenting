*[AllowedIPs]: WireGuard's peer-selection and packet-allow list for tunnel traffic. Some tools also use it to install routes.
*[ARP]: Address Resolution Protocol. IPv4's local-link discovery mechanism for mapping an IP address to a link-layer address.
*[autonomous system]: One independently controlled network boundary. In real Internet routing, an autonomous system is identified by an ASN.
*[BGP]: Border Gateway Protocol. Routers use BGP to exchange network reachability with other routers.
*[BIRD]: A routing daemon that can learn, select, filter, and install routes.
*[control plane]: The system that decides or communicates reachability, such as BIRD and BGP.
*[convergence]: The network settling on usable routes after a routing change or failure.
*[data plane]: The system that actually forwards packets, such as Linux route lookup, interfaces, tunnels, and packet filters.
*[DNS]: Domain Name System. The naming system that maps names to data such as IP addresses.
*[DN42]: A community overlay network used for learning and experimenting with routing, DNS, and network services.
*[endpoint]: The underlay address and UDP port where a WireGuard peer receives tunnel packets.
*[export filter]: A rule that decides which routes a router announces to a neighbor.
*[handshake]: Evidence that WireGuard peers exchanged setup traffic.
*[ICMP]: Internet Control Message Protocol. The protocol family used by tools such as ping for echo requests and replies.
*[ICMPv6]: Internet Control Message Protocol for IPv6. IPv6 ping and NDP use ICMPv6 messages.
*[import filter]: A rule that decides which routes a router accepts from a neighbor.
*[inner packet]: The packet the overlay network thinks it is sending before a tunnel wraps it.
*[longest-prefix match]: The route lookup rule that the most-specific matching route wins.
*[outer packet]: The packet that carries a tunneled inner packet across the underlay.
*[NDP]: Neighbor Discovery Protocol. IPv6's local-link neighbor discovery system.
*[nftables]: Linux's modern packet-filtering framework.
*[observability]: The habit of using system evidence to understand what is happening.
*[overlay]: The logical network carried by an underlay.
*[return path]: The route a reply packet uses to get back to the original sender.
*[rollback proof]: Evidence that cleanup removed the state a lab created.
*[route advertisement]: Telling another router that you can carry traffic for a prefix.
*[route leak]: Accidentally announcing or accepting routes that should not cross a routing boundary.
*[split DNS]: Using different DNS resolvers or answers depending on where a query is made.
*[underlay]: The network that carries an overlay tunnel.
*[ULA]: Unique Local Address. IPv6 private addressing intended for local networks.
*[VPN]: A tool that creates a private-looking network path across another network.
*[WireGuard]: A VPN protocol commonly used to create encrypted tunnel links.
