# Pocket Internet Service

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
