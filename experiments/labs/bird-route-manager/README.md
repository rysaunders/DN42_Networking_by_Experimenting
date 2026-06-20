# BIRD Route Manager

## Lab Metadata

```yaml
experiment_id: experiments/labs/bird-route-manager
status: validated
safety_level: local-routing-daemon
chapter: docs/part-01-first-principles/05-bird-as-route-manager.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - bird2
  - birdc
setup_assumptions:
  - temporary namespace name pocket-bird is available
  - BIRD 2 and birdc are installed in the Linux environment
cleanup_guarantees:
  - stops the lab-scoped BIRD process
  - deletes namespace pocket-bird
  - removes temporary BIRD config and socket files
expected_state:
  - one namespace: pocket-bird
  - one lab-scoped BIRD daemon
  - BIRD static route before kernel export
  - Linux route after explicit kernel export
  - no service listeners
validation_commands:
  - bash -n experiments/labs/bird-route-manager/run.sh
  - experiments/labs/bird-route-manager/run.sh
  - ip netns list | grep -q pocket-bird returns no match after cleanup
transcript: experiments/transcripts/bird-route-manager-20260619T144400Z.txt
technical_review:
  required: true
  status: deferred
```

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
