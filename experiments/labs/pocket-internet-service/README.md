# Pocket Internet Service

## Lab Metadata

```yaml
experiment_id: experiments/labs/pocket-internet-service
status: validated
safety_level: local-routing-daemon
chapter: docs/part-01-first-principles/07-operate-a-service.md
standalone: true
requires_capabilities:
  - root-or-sudo
  - CAP_NET_ADMIN
  - iproute2
  - bird2
  - birdc
  - python3
  - curl
setup_assumptions:
  - temporary namespace names pocket-as1 through pocket-as4 are available
  - Python 3 HTTP server module is available
cleanup_guarantees:
  - stops lab-scoped BIRD and Python HTTP processes
  - deletes all pocket-as* namespaces named by the lab
  - removes temporary web root, BIRD config, socket, and PID files
expected_state:
  - four BGP-speaking namespaces
  - Python HTTP listener bound to 172.20.3.1:8080 inside pocket-as3
  - curl from pocket-as1 reaches the service using explicit source address
  - no host-exposed listener remains after cleanup
validation_commands:
  - bash -n experiments/labs/pocket-internet-service/run.sh
  - experiments/labs/pocket-internet-service/run.sh
  - ip netns list | grep -E 'pocket-as[1-4]' returns no match after cleanup
transcript: experiments/transcripts/pocket-internet-service-20260618T103858Z.txt
technical_review:
  required: true
  status: deferred
```

This lab validates the service chapter for Pocket Internet.

It builds the four-namespace Pocket Internet ring with BIRD/BGP, starts an HTTP
service inside `pocket-as3`, and proves that `pocket-as1` reaches the service
through BGP-learned routes rather than direct attachment.

The lab also includes a failure branch: the service first binds to `127.0.0.1`
inside `pocket-as3`, which makes it local to that namespace only. After that
fails from `pocket-as1`, the service is restarted on `172.20.3.1`.

Run from the repository root inside the Linux lab environment:

```sh
experiments/labs/pocket-internet-service/run.sh
```

Requirements:

- Linux network namespaces
- root privileges
- BIRD 2 and `birdc`
- Python 3
- `curl`
- `ss`

The script records a transcript under ignored `experiments/transcripts/local/` by default.
