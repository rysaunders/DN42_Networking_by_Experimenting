# DNS And Naming Foundation

??? info "Maintainer metadata"
    ```yaml
    chapter_id: part-01-14-dns-and-naming-foundation
    status: published-draft
    safety_level: local-lab
    lab_id: experiments/labs/dns-and-naming-foundation
    depends_on:
      - part-01-07-operate-service
      - part-01-13-packet-filtering-foundation
    transcript: experiments/transcripts/dns-and-naming-foundation-20260620T000000Z.txt
    source_ids:
      - rfc-1034
      - rfc-1035
      - rfc-6761
      - dnsmasq-docs
    tested_environment:
      host: macOS + OrbStack
      distro: Ubuntu 24.04 noble
      kernel: recorded in transcript
      bird: not used
      wireguard_tools: not used
    beginner_review:
      status: deferred
      note: Deferred in this pass; chapter is transcript-backed and ready for the next beginner review loop.
    technical_review:
      required: true
      status: deferred
      note: Local-only DNS lab validated; DN42 split-DNS resolver guidance requires fresh source review later.
    ```

## Reader Starting Point

This chapter assumes you know what a namespace, interface, address, route lookup, service, listener, port, packet filter, and rollback are.

So far, most labs have used raw addresses:

```text
curl http://10.88.0.2:8080/
```

That is useful while learning routing because it removes one moving part. Real networks usually add another question before a packet is sent:

> What address does this name mean right now?

This chapter adds that question without changing the host or public DNS.

## New Terms

| Term | Plain-language meaning | Concrete example in this chapter |
| --- | --- | --- |
| DNS | The naming system that maps names to data such as IP addresses. | `www.pocket.test` resolves to `10.89.0.2`. |
| Name resolution | Turning a name into an address or other DNS answer. | `getent hosts www.pocket.test` |
| Resolver | The client-side component that asks DNS questions for programs. | The resolver inside `pocket-dns-client`. |
| Nameserver | A server that answers DNS questions. | `dnsmasq` inside `pocket-dns-server`. |
| Authoritative answer | An answer from the place configured to know a name directly. | `dnsmasq` answering for `www.pocket.test`. |
| Recursive resolver | A resolver that can chase answers through the wider DNS system. | Not used in this local lab. |
| Split DNS | Different DNS answers or resolvers depending on where the query is made. | Later, `.dn42` names should use DN42-aware resolvers without changing all DNS. |

## Question

Can routing work while naming fails?

Can naming work while the service still fails?

## Hypothesis

If the client has a route to `10.89.0.2`, it can reach the server address directly.

If the client resolver points at the lab nameserver, `www.pocket.test` should resolve to `10.89.0.2`.

If the DNS name resolves but the HTTP listener is stopped, name resolution should still work and the service should fail.

## Mental Model

There are now four separate checks:

```text
name -> resolver -> nameserver -> address -> route lookup -> service listener
```

Those checks answer different questions:

- resolver behavior: who does the client ask?
- DNS server behavior: what answer does the nameserver give?
- routing behavior: where does Linux send packets for that answer?
- service behavior: is a program listening at the destination address and port?

```mermaid
flowchart LR
  app["curl www.pocket.test"] --> resolver["client resolver<br/>/etc/netns/.../resolv.conf"]
  resolver --> dns["dnsmasq nameserver<br/>10.89.0.2"]
  dns --> answer["A record<br/>10.89.0.2"]
  answer --> route["route lookup<br/>dev client0"]
  route --> service["HTTP listener<br/>10.89.0.2:8080"]
```

## Why This Matters

DN42 has names too. Eventually you will see `.dn42` names, split DNS, local resolvers, and service names that only make sense inside DN42.

That later setup is easier if you already have the simpler split in your head:

- a route can be correct while a name does not resolve,
- a name can resolve while the service is down,
- a DNS server can answer locally without being a general Internet resolver,
- changing the resolver for one lab namespace is not the same as changing DNS for the host.

This chapter does not recommend current DN42 resolvers. That guidance belongs in the DN42 DNS chapter after fresh source review.

## Safety Boundaries

Safety level: local lab.

- The lab uses two temporary Linux network namespaces.
- The lab creates one veth pair.
- The lab starts one `dnsmasq` nameserver inside `pocket-dns-server`.
- The lab starts one Python HTTP listener inside `pocket-dns-server`.
- The lab writes resolver configuration only under `/etc/netns/pocket-dns-client/` inside the Linux lab environment.
- The lab does not edit macOS DNS settings.
- The lab does not edit the Linux host's normal `/etc/resolv.conf`.
- The lab does not query public DNS.
- Rollback deletes both namespaces, stops both lab processes, and removes the namespace resolver file.

Before the lab, capture the host baseline:

```sh
ip netns list
cat /etc/resolv.conf
```

## Lab Requirements

Run this chapter inside the Linux lab environment from a root shell. The commands below are written without `sudo` so they stay readable and match the validation transcript.

Check the required tools:

```sh
id
ip -V
dnsmasq --version
python3 --version
curl --version
command -v pkill
getent --help >/dev/null && echo "getent is available"
```

Expected observations:

- `id` should show `uid=0(root)`. If it does not, enter a root lab shell before continuing.
- `ip -V` should print the installed `iproute2` version.
- `dnsmasq --version` should print the dnsmasq version.
- `python3 --version` and `curl --version` should print installed versions.
- `command -v pkill` should print a path to `pkill`, which the rollback step uses to stop the HTTP listener inside the namespace.

The repeatable validation script lives at:

```text
experiments/labs/dns-and-naming-foundation/run.sh
```

The validated transcript for this experiment is:

```text
experiments/transcripts/dns-and-naming-foundation-20260620T000000Z.txt
```

## What You Will Build

You will create two namespaces:

```text
pocket-dns-client client0 10.89.0.1/30  <---- veth ---->  10.89.0.2/30 server0 pocket-dns-server
```

Inside `pocket-dns-server`, you will run:

```text
DNS nameserver: 10.89.0.2:53
HTTP service:   10.89.0.2:8080
```

The nameserver will answer one local name:

```text
www.pocket.test -> 10.89.0.2
```

`pocket.test` is used only as a lab name. The `.test` top-level domain is reserved for testing, so it is a better lab habit than inventing a realistic-looking public domain. It is not DN42.

## Step 1: Clean Up Any Old Lab State

Remove old copies of the lab namespaces and files:

```sh
ip netns delete pocket-dns-client 2>/dev/null || true
ip netns delete pocket-dns-server 2>/dev/null || true
rm -rf /tmp/dns-and-naming-foundation
rm -rf /etc/netns/pocket-dns-client
rm -rf /etc/netns/pocket-dns-server
```

Check that no lab namespaces remain:

```sh
ip netns list | grep -E '^(pocket-dns-client|pocket-dns-server)( |$)' || true
```

No output is the expected clean state.

## Step 2: Create The Namespaces And Link

Create the namespaces:

```sh
ip netns add pocket-dns-client
ip netns add pocket-dns-server
```

Create one veth pair and move one end into each namespace:

```sh
ip link add client0 type veth peer name server0
ip link set client0 netns pocket-dns-client
ip link set server0 netns pocket-dns-server
```

## Step 3: Add Addresses And Bring The Link Up

Add one address on each end:

```sh
ip -n pocket-dns-client addr add 10.89.0.1/30 dev client0
ip -n pocket-dns-server addr add 10.89.0.2/30 dev server0
```

Bring up loopback and the veth interfaces:

```sh
ip -n pocket-dns-client link set lo up
ip -n pocket-dns-client link set client0 up
ip -n pocket-dns-server link set lo up
ip -n pocket-dns-server link set server0 up
```

Inspect the connected routes:

```sh
ip -n pocket-dns-client route
ip -n pocket-dns-server route
```

Both namespaces should have a connected route for `10.89.0.0/30`.

## Step 4: Prove Routing Before Naming

Ask Linux how the client would reach the server address:

```sh
ip -n pocket-dns-client route get 10.89.0.2
```

Expected output includes:

```text
10.89.0.2 dev client0 src 10.89.0.1
```

Now ping the server by address:

```sh
ip netns exec pocket-dns-client ping -c 1 -W 2 10.89.0.2
```

That proves the link and route are working. It says nothing about names yet.

Try the name before any lab resolver exists:

```sh
ip netns exec pocket-dns-client getent hosts www.pocket.test || true
```

Expected observation: no address is printed.

Read that as:

> Routing works, but the client does not yet know who should answer `www.pocket.test`.

## Step 5: Start A Local Nameserver

Create a work directory:

```sh
mkdir -p /tmp/dns-and-naming-foundation
```

Start `dnsmasq` inside the server namespace:

```sh
ip netns exec pocket-dns-server dnsmasq \
  --no-daemon \
  --no-resolv \
  --bind-interfaces \
  --interface=server0 \
  --listen-address=10.89.0.2 \
  --address=/www.pocket.test/10.89.0.2 \
  --log-queries \
  --log-facility=- \
  >/tmp/dns-and-naming-foundation/dnsmasq.log 2>&1 &
```

Save the process ID so rollback can stop it:

```sh
DNS_PID=$!
```

Give it a moment, then check that something is listening on DNS port `53`:

```sh
sleep 1
ip netns exec pocket-dns-server ss -lunp
```

Look for `10.89.0.2:53`.

## Step 6: Point Only The Client Namespace At The Lab Nameserver

Create a namespace-specific resolver file:

```sh
mkdir -p /etc/netns/pocket-dns-client
printf 'nameserver 10.89.0.2\noptions timeout:1 attempts:1\n' > /etc/netns/pocket-dns-client/resolv.conf
cat /etc/netns/pocket-dns-client/resolv.conf
```

This file is the key containment boundary.

When you run a command with:

```text
ip netns exec pocket-dns-client ...
```

Linux uses the resolver file for that namespace. The normal Linux host resolver file is not changed.

## Step 7: Resolve The Name

Ask for the lab name:

```sh
ip netns exec pocket-dns-client getent hosts www.pocket.test
```

Expected output:

```text
10.89.0.2       www.pocket.test
```

Now inspect the DNS server log:

```sh
tail -n 20 /tmp/dns-and-naming-foundation/dnsmasq.log
```

You should see `www.pocket.test` and `10.89.0.2` in the log.

This proves two things:

- the client resolver asked the lab nameserver,
- the lab nameserver answered with the service address.

## Step 8: Start The Service And Use The Name

Create the service content:

```sh
mkdir -p /tmp/dns-and-naming-foundation/web
printf 'hello from named pocket service\n' > /tmp/dns-and-naming-foundation/web/index.html
```

Start the HTTP listener inside the server namespace:

```sh
ip netns exec pocket-dns-server python3 -m http.server 8080 \
  --bind 10.89.0.2 \
  --directory /tmp/dns-and-naming-foundation/web \
  >/tmp/dns-and-naming-foundation/http.log 2>&1 &
```

Save the process ID:

```sh
HTTP_PID=$!
```

Give it a moment, then inspect listeners:

```sh
sleep 1
ip netns exec pocket-dns-server ss -ltnp
```

Fetch the service by name from the client namespace:

```sh
ip netns exec pocket-dns-client curl -sS --max-time 3 http://www.pocket.test:8080/
```

Expected output:

```text
hello from named pocket service
```

That command used both systems:

- DNS turned `www.pocket.test` into `10.89.0.2`,
- routing carried HTTP traffic to `10.89.0.2:8080`.

## Step 9: Failure Mode: Route Works, Name Fails

Ask for a name the lab nameserver does not know:

```sh
ip netns exec pocket-dns-client getent hosts missing.pocket.test || true
```

Expected observation: no address is printed.

Now prove address-based routing and service access still work:

```sh
ip -n pocket-dns-client route get 10.89.0.2
ip netns exec pocket-dns-client curl -sS --max-time 3 http://10.89.0.2:8080/
```

Expected service output:

```text
hello from named pocket service
```

Read that as:

> The network path is fine. This failure is naming.

## Step 10: Failure Mode: Name Works, Service Fails

Resolve the working name again:

```sh
ip netns exec pocket-dns-client getent hosts www.pocket.test
```

Stop the HTTP service:

```sh
ip netns exec pocket-dns-server pkill -f "python3 -m http.server 8080" || true
wait "$HTTP_PID" 2>/dev/null || true
HTTP_PID=""
```

The name should still resolve:

```sh
ip netns exec pocket-dns-client getent hosts www.pocket.test
```

But HTTP should now fail:

```sh
ip netns exec pocket-dns-client curl -sS --connect-timeout 2 --max-time 3 http://www.pocket.test:8080/ || true
```

Read that as:

> Naming still works. The service listener is gone.

This is the same troubleshooting discipline as earlier chapters. Do not collapse separate questions into one vague statement like "the network is broken."

## Step 11: Roll Back

Stop the DNS server if it is still running:

```sh
kill "$DNS_PID" 2>/dev/null || true
wait "$DNS_PID" 2>/dev/null || true
DNS_PID=""
```

Delete the namespaces and temporary files:

```sh
ip netns delete pocket-dns-client 2>/dev/null || true
ip netns delete pocket-dns-server 2>/dev/null || true
rm -rf /tmp/dns-and-naming-foundation
rm -rf /etc/netns/pocket-dns-client
rm -rf /etc/netns/pocket-dns-server
```

Confirm cleanup:

```sh
ip netns list | grep -E '^(pocket-dns-client|pocket-dns-server)( |$)' || true
```

No output is expected.

## What You Should Have Seen

You built a small naming system inside Pocket Internet:

- `pocket-dns-client` had a route to `10.89.0.2`,
- `pocket-dns-server` answered DNS for `www.pocket.test`,
- the client namespace used a namespace-specific resolver file,
- `curl` could fetch a service by name,
- an unknown name failed while address-based service access still worked,
- a known name kept resolving after the HTTP listener stopped.

The important split is:

```text
DNS answer != route exists != service is listening
```

All three are required for a named service to work.

## Checkpoint

You can now explain:

- why name resolution is separate from route lookup,
- why a local nameserver can answer lab names without changing host DNS,
- why a service can fail even after DNS returns the correct address,
- why this prepares for `.dn42` split DNS later.

Still okay if fuzzy:

- recursive resolver internals,
- DNS delegation,
- DNS record types beyond address records,
- DN42 resolver choices.

Next we need:

- to carry this naming model into the later DN42 DNS chapter,
- to treat `.dn42` resolver guidance as current-network material that needs fresh source review.
