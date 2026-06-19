# BIRD Route Manager

This lab validates the BIRD-as-a-local-route-manager chapter.

It creates one temporary namespace, starts one lab-scoped BIRD process, and
shows three separate route views:

- the local interface address,
- BIRD's own route table,
- Linux routes exported from BIRD through `protocol kernel`.

The lab proves:

- `protocol direct` can learn from an address on a local interface,
- `protocol static` can create a route inside BIRD,
- BIRD knowing a route does not automatically mean Linux will use it,
- `protocol kernel` export is the boundary where selected BIRD routes enter the
  Linux kernel route table,
- rollback stops BIRD and removes the namespace and temporary files.

Run from the repository root inside the Linux lab environment:

```sh
experiments/labs/bird-route-manager/run.sh
```

Requirements:

- Linux network namespaces
- root privileges
- BIRD 2 and `birdc`
- `iproute2`

The script records a transcript under ignored `experiments/transcripts/local/`
by default.
