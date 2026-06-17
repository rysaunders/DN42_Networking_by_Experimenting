# Pocket Internet BGP

This lab validates the BIRD/BGP chapter for Pocket Internet.

It builds the four-namespace Pocket Internet ring, starts one BIRD instance per
namespace, establishes local BGP sessions between different lab AS numbers over
veth links, advertises service loopback addresses, exports selected BGP routes
into the Linux kernel, and then isolates one AS to observe route withdrawal and
convergence.

Run from the repository root inside the Linux lab environment:

```sh
experiments/labs/pocket-internet-bgp/run.sh
```

Requirements:

- Linux network namespaces
- root privileges
- BIRD 2 and `birdc`
- `iproute2`

The script records a transcript under `experiments/transcripts/`.
