# DNS And Naming Foundation Lab

This lab validates the chapter:

```text
docs/part-01-first-principles/14-dns-and-naming-foundation.md
```

It creates two temporary namespaces:

```text
pocket-dns-client client0 10.89.0.1/30  <---- veth ---->  10.89.0.2/30 server0 pocket-dns-server
```

Inside `pocket-dns-server`, it starts:

- `dnsmasq` on `10.89.0.2:53`,
- Python HTTP server on `10.89.0.2:8080`.

Inside `pocket-dns-client`, it writes a namespace-local resolver file:

```text
/etc/netns/pocket-dns-client/resolv.conf
```

The lab proves:

- route lookup works before naming,
- `www.pocket.test` resolves to `10.89.0.2`,
- HTTP works by name,
- route and service can work while an unknown name fails,
- name resolution can work while the HTTP service is stopped.

Run from the repository root inside a root Linux lab shell:

```sh
bash experiments/labs/dns-and-naming-foundation/run.sh
```

Local runs write transcripts under:

```text
experiments/transcripts/local/
```

Set `LAB_TRANSCRIPT_PATH` only when intentionally regenerating the checked transcript referenced by the chapter.
