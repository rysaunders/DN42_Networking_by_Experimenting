*[address space]: The full set of addresses that can exist in an IP version or prefix.
*[autonomous system]: One independently controlled network boundary. In real Internet routing, an autonomous system is identified by an ASN.
*[BGP]: Border Gateway Protocol. Routers use BGP to exchange network reachability with other routers.
*[BIRD]: A routing daemon that can learn, select, filter, and install routes.
*[connected route]: A route Linux creates automatically for a prefix assigned directly to an interface.
*[default route]: The fallback route used when no more-specific route matches. In IPv4 it is also written as `0.0.0.0/0`.
*[DN42]: A community overlay network used for learning and experimenting with routing, DNS, and network services.
*[export filter]: A rule that decides which routes a router announces to a neighbor.
*[host route]: A route for exactly one IP address, such as `172.20.30.42/32`.
*[import filter]: A rule that decides which routes a router accepts from a neighbor.
*[longest-prefix match]: The route lookup rule that the most-specific matching route wins.
*[network namespace]: An isolated Linux network stack with its own interfaces, addresses, and routes.
*[network stack]: The part of an operating system that owns interfaces, addresses, routes, and packet handling.
*[next hop]: The next router a packet should be sent to.
*[on-link]: Reachable through a local interface without first sending the packet to another IP router.
*[prefix length]: The number after `/`; a larger number means a smaller, more-specific prefix.
*[return path]: The route a reply packet uses to get back to the original sender.
*[route advertisement]: Telling another router that you can carry traffic for a prefix.
*[route leak]: Accidentally announcing or accepting routes that should not cross a routing boundary.
*[route lookup]: Asking Linux which route it would use for a packet.
*[service loopback]: A stable address on `lo` that represents a service or prefix a router could advertise later.
*[static route]: A route written by hand.
*[underlay]: The network that carries an overlay tunnel.
*[veth pair]: A virtual Ethernet cable with two ends. A packet sent into one end comes out the other.
*[WireGuard]: A VPN protocol commonly used to create encrypted tunnel links.
