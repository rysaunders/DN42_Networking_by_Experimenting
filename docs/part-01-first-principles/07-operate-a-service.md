# Operate a Service Inside Pocket Internet

??? info "Maintainer metadata"
    ```yaml
    chapter_id: part-01-07-operate-service
    status: published-draft
    safety_level: local-routing-daemon
    lab_id: experiments/labs/pocket-internet-service
    depends_on:
      - part-01-06-bgp-before-dn42
    transcript: experiments/transcripts/pocket-internet-service-20260618T103858Z.txt
    source_ids:
      - bird-docs
    tested_environment:
      host: macOS + OrbStack
      distro: recorded in transcript
      kernel: recorded in transcript
      bird: recorded in transcript
      wireguard_tools: not used
    beginner_review:
      status: complete
      note: Reader feedback recorded; tooltip and lab-continuity concerns tracked for follow-up.
    technical_review:
      required: true
      status: deferred
      note: Local service lab validated; service-exposure guidance requires later technical review.
    ```

## Reader Starting Point

This chapter assumes you have completed BGP Before DN42. You should know what a namespace, service loopback, route lookup, return path, BIRD, BGP session, route advertisement, import filter, export filter, kernel protocol, and convergence are.

The previous chapter proved that BIRD and BGP can install routes. This chapter gives those routes a job.

> Routes are not the goal. Reachable services are the goal.

You will run a small HTTP service on `pocket-as3` and reach it from `pocket-as1` through the Pocket Internet route table.

This is still a local lab. Host-to-lab access is intentionally left for a later extension because it adds a different question: how does a machine outside Pocket Internet enter the lab?

## New Terms

| Term | Plain-language meaning | Example in this lab |
| --- | --- | --- |
| Service | A program that listens for network connections and responds. | Python's HTTP server |
| Listener | The address and port where a service waits for connections. | `172.20.3.1:8080` |
| Bind address | The local address a service attaches to. | `127.0.0.1` or `172.20.3.1` |
| Port | A number identifying a service on an address. | `8080` |
| HTTP | A simple request/response protocol used by web servers and clients. | `curl http://172.20.3.1:8080/` |
| Application traffic | Traffic for a real program instead of a routing probe. | HTTP instead of ping |

## Question

Can a service inside one Pocket Internet namespace be reached from another namespace using BGP-learned routes?

## Hypothesis

If `pocket-as3` runs a service bound to its advertised service loopback, and `pocket-as1` has a BGP-learned route to that loopback, then `pocket-as1` can fetch application data from the service.

If the service binds only to `127.0.0.1`, then it works inside `pocket-as3` but fails from `pocket-as1`, even though the route exists.

## Mental Model

The route gets the packet to the service address. The listener decides whether a program is actually waiting there.

```text
pocket-as1 curl
  source 172.20.1.1
        |
        v
BGP-learned route to 172.20.3.1
        |
        v
pocket-as3 listener
  172.20.3.1:8080
```

Two things must be true at the same time:

- Linux can route to `172.20.3.1`.
- A service is listening on `172.20.3.1:8080`.

Ping proves network reachability. HTTP proves a program can use that reachability.

## Why It Matters

DN42 is useful because people operate services on it: DNS, websites, monitoring, dashboards, experiments, and debugging tools.

The same separation applies there:

- BGP can make a prefix reachable.
- Linux can forward packets toward that prefix.
- A service still has to listen on the right address.
- Replies still need a return path.

When a service fails, the bug might be routing, listener binding, firewall policy, source address, or the application itself. This lab gives you a small version of that troubleshooting shape.

## Safety Boundaries

Safety level: routing-daemon lab.

- The lab uses only temporary Linux network namespaces.
- The lab starts BIRD manually inside those namespaces.
- The lab starts one temporary Python HTTP service inside `pocket-as3`.
- The service listens only inside Pocket Internet.
- The lab does not add host default routes.
- The lab does not expose the service on the macOS host or public Internet.
- Rollback stops the service, stops BIRD, deletes the namespaces, and removes temporary files.

Before the lab, capture the host baseline:

```sh
ip netns list
ip route get 1.1.1.1
```

## Lab Requirements

Run this chapter inside the Linux lab environment from a root shell. The commands below are written without `sudo` so they stay readable and match the validation transcript.

Check the required tools before continuing:

```sh
id
ip -V
bird --version
command -v birdc
python3 --version
curl --version
```

Expected observations:

- `id` should show `uid=0(root)` if you are using a root lab shell.
- `ip -V` should print the installed `iproute2` version.
- `bird --version` should report BIRD 2.
- `command -v birdc` should print a path.
- `python3 --version` and `curl --version` should print installed versions.

The repeatable validation script is standalone and builds the whole service lab from scratch:

```text
experiments/labs/pocket-internet-service/run.sh
```

The validated transcript for this experiment is:

```text
experiments/transcripts/pocket-internet-service-20260618T103858Z.txt
```

## Checkpoint Required

This lab is a dependent extension of the BGP Pocket Internet from the previous chapter, with one service added inside `pocket-as3`.

That dependency is not ideal, but it is explicit: the lesson starts from a named checkpoint instead of hidden state. Every chapter should still leave a reader with rollback commands that remove the state it created.

If you already have the BGP lab running, you can continue from it. The checkpoint is this: BGP has installed a route from `pocket-as1` to `172.20.3.1`.

You should be able to run:

```sh title="Verify the BGP checkpoint from the root Linux shell"
ip -n pocket-as1 route show 172.20.3.1
ip -n pocket-as1 route get 172.20.3.1 from 172.20.1.1
```

Expected observations:

- `route show` includes `proto bird`,
- `route get` sends traffic through one of `pocket-as1`'s neighbors.

If those commands do not show a BGP-learned route, rebuild the BGP Pocket Internet before continuing manually.

## Resume Path

Use this path only after you have built the BGP lab manually at least once. The learning path is still to build the route-exchange machinery yourself before adding a service.

To restore the full service-lab state in one repeatable run, use the validation script:

```sh
bash experiments/labs/pocket-internet-service/run.sh
```

That script creates the BGP topology and service, validates the expected observations, then rolls everything back. It is useful for repeat validation, not a substitute for the first manual build.

## What You Will Build

You will use:

- `pocket-as1` as the client namespace,
- `pocket-as3` as the service namespace,
- `172.20.1.1/32` as the client service loopback and source address,
- `172.20.3.1/32` as the server service loopback,
- TCP port `8080` for the HTTP service.

The service content is intentionally plain:

```text
hello from pocket-as3 service loopback
```

If `pocket-as1` can fetch that line from `172.20.3.1:8080`, Pocket Internet is carrying application traffic.

## Step 1: Create Service Content

Create a temporary directory and one file:

```sh title="Create service content from the root Linux shell"
mkdir -p /tmp/pocket-internet-service/www
printf 'hello from pocket-as3 service loopback\n' > /tmp/pocket-internet-service/www/index.html
cat /tmp/pocket-internet-service/www/index.html
```

Expected output:

```text
hello from pocket-as3 service loopback
```

This file lives in the Linux lab environment, not inside a namespace by itself. The service process will read it after you start that process inside `pocket-as3`.

## Step 2: Prove Routing Exists Before The Service

From the BGP chapter, `pocket-as1` should already have a BGP-learned route:

```sh title="Check the client route before starting a service"
ip -n pocket-as1 route show 172.20.3.1
```

Expected output looks like:

```text
172.20.3.1 via 10.42.12.2 dev as1-as2 proto bird metric 32
```

Ask Linux how a packet would leave:

```sh title="Check how pocket-as1 would reach the service loopback"
ip -n pocket-as1 route get 172.20.3.1 from 172.20.1.1
```

Now try HTTP before a service exists:

```sh title="Try HTTP from pocket-as1 before a listener exists"
ip netns exec pocket-as1 curl \
  --connect-timeout 2 \
  --max-time 4 \
  --interface 172.20.1.1 \
  --fail \
  http://172.20.3.1:8080/
```

Expected result: it fails.

That failure is useful. The route can exist while the service does not. Routing gets you to the destination address; it does not create a program listening there.

!!! success "What this proves"
    A route to the service address can exist while no application is reachable there.

!!! warning "What this does not prove"
    It does not prove routing is broken. The failure is expected because no listener exists on `172.20.3.1:8080` yet.

## Step 3: Bind The Service To The Wrong Address

Start the HTTP service inside `pocket-as3`, but bind it to `127.0.0.1`:

```sh title="Start a deliberately wrong listener inside pocket-as3"
ip netns exec pocket-as3 python3 -m http.server 8080 \
  --bind 127.0.0.1 \
  --directory /tmp/pocket-internet-service/www \
  > /tmp/pocket-internet-service/service.log 2>&1 &
echo "$!" > /tmp/pocket-internet-service/service.pid
sleep 1
```

That starts the service in the background and saves its process ID. The log goes to `/tmp/pocket-internet-service/service.log`.

Inspect the listener:

```sh title="Inspect listeners inside pocket-as3"
ip netns exec pocket-as3 ss -ltnp 'sport = :8080'
```

`ss` shows sockets. A socket is one end of a network conversation. With these options, `ss` lists listening TCP sockets and filters the output to source port `8080`.

In the output, read `Local Address:Port` as "where the service is listening."

Expected observation:

```text
LISTEN ... 127.0.0.1:8080 ...
```

Now test from inside `pocket-as3`:

```sh title="Fetch the wrong listener locally inside pocket-as3"
ip netns exec pocket-as3 curl --connect-timeout 2 --max-time 4 --fail http://127.0.0.1:8080/
```

Expected output:

```text
hello from pocket-as3 service loopback
```

The service is alive. But it is alive only on `127.0.0.1` inside `pocket-as3`.

!!! success "What this proves"
    The HTTP process is running and reachable from inside the same namespace on loopback.

!!! warning "What this does not prove"
    It does not prove other namespaces can reach the service address. A listener bound to `127.0.0.1` is local to `pocket-as3`.

Try from `pocket-as1`:

```sh title="Try HTTP from pocket-as1 while the listener is bound to the wrong address"
ip netns exec pocket-as1 curl \
  --connect-timeout 2 \
  --max-time 4 \
  --interface 172.20.1.1 \
  --fail \
  http://172.20.3.1:8080/
```

Expected result: it fails.

Read that failure carefully:

- the route to `172.20.3.1` exists,
- the service process exists,
- the service is bound to the wrong address for remote clients.

This is a common real-world shape. "The service is running" is not the same as "the service is reachable on the address the network is routing to."

!!! success "What this proves"
    Binding matters. A running service can still be unreachable from the network when it listens on the wrong address.

!!! warning "What this does not prove"
    It does not prove the BGP route disappeared. The route can still be correct while the listener is wrong.

Inspect the service log if you want to see the local request:

```sh title="Inspect the HTTP service log"
cat /tmp/pocket-internet-service/service.log
```

Stop the wrong listener before continuing:

```sh title="Stop the current HTTP listener"
ip netns exec pocket-as3 kill "$(cat /tmp/pocket-internet-service/service.pid)"
rm -f /tmp/pocket-internet-service/service.pid
```

## Step 4: Bind The Service To The Service Loopback

Start the HTTP service again, this time bound to `172.20.3.1`:

```sh title="Start the service listener on pocket-as3 service loopback"
ip netns exec pocket-as3 python3 -m http.server 8080 \
  --bind 172.20.3.1 \
  --directory /tmp/pocket-internet-service/www \
  > /tmp/pocket-internet-service/service.log 2>&1 &
echo "$!" > /tmp/pocket-internet-service/service.pid
sleep 1
```

As before, the service is running in the background while you test it.

Inspect the listener:

```sh title="Inspect listeners inside pocket-as3"
ip netns exec pocket-as3 ss -ltnp 'sport = :8080'
```

Expected observation:

```text
LISTEN ... 172.20.3.1:8080 ...
```

Now fetch the service from `pocket-as1`:

```sh title="Fetch the service from pocket-as1"
ip netns exec pocket-as1 curl \
  --connect-timeout 2 \
  --max-time 4 \
  --interface 172.20.1.1 \
  --fail \
  http://172.20.3.1:8080/
```

Expected output:

```text
hello from pocket-as3 service loopback
```

The `--interface 172.20.1.1` option tells `curl` to use `pocket-as1`'s service loopback as the source address. That makes the return path explicit: `pocket-as3` must know how to reply to `172.20.1.1`.

!!! success "What this proves"
    Routing, listener binding, and the return path are all sufficient for this HTTP request.

!!! warning "What this does not prove"
    It does not prove every port or every service on `pocket-as3` is reachable. It proves this listener on this address and port works.

## Step 5: Verify Forward Path And Return Path

Forward path from client to service:

```sh title="Check how pocket-as1 would reach the service loopback"
ip -n pocket-as1 route get 172.20.3.1 from 172.20.1.1
```

Return path from service back to client:

```sh title="Check the service return path from pocket-as3"
ip -n pocket-as3 route get 172.20.1.1 from 172.20.3.1
```

Those two commands are the routing proof.

The HTTP response is the application proof.

Inspect the service log:

```sh title="Inspect the HTTP service log"
cat /tmp/pocket-internet-service/service.log
```

You should see the client source address:

```text
172.20.1.1 - - [...] "GET / HTTP/1.1" 200 -
```

That line matters. It says the service saw the request as coming from `172.20.1.1`, not from a local shortcut.

## Troubleshooting Branches

### Route Exists But HTTP Fails

Check whether anything is listening:

```sh title="Inspect listeners inside pocket-as3"
ip netns exec pocket-as3 ss -ltnp 'sport = :8080'
```

If nothing is listening, routing is not the problem yet.

### Service Works Locally But Not Remotely

Look at the local address in `ss`.

If it says:

```text
127.0.0.1:8080
```

then only clients inside `pocket-as3` can use that listener through namespace-local loopback.

For this lab, it should say:

```text
172.20.3.1:8080
```

### HTTP Connects But Hangs Or Replies Fail

Check the return path:

```sh title="Check the service return path from pocket-as3"
ip -n pocket-as3 route get 172.20.1.1 from 172.20.3.1
```

Packets need a way back. A forward route alone is not a working service path.

## Rollback

Stop the HTTP service if it is still running:

```sh title="Stop the HTTP service during rollback"
if [ -f /tmp/pocket-internet-service/service.pid ]; then
  ip netns exec pocket-as3 kill "$(cat /tmp/pocket-internet-service/service.pid)" 2>/dev/null || true
  rm -f /tmp/pocket-internet-service/service.pid
fi
```

Stop the lab BIRD processes if they are still running:

```sh
for ns in pocket-as1 pocket-as2 pocket-as3 pocket-as4; do
  for dir in /tmp/pocket-internet-bgp /tmp/pocket-internet-service; do
    if [ -f "${dir}/${ns}.pid" ]; then
      ip netns exec "$ns" kill "$(cat "${dir}/${ns}.pid")" 2>/dev/null || true
    fi
  done
done
```

Delete the namespaces and temporary files:

```sh
ip netns delete pocket-as1 2>/dev/null || true
ip netns delete pocket-as2 2>/dev/null || true
ip netns delete pocket-as3 2>/dev/null || true
ip netns delete pocket-as4 2>/dev/null || true
rm -rf /tmp/pocket-internet-bgp
rm -rf /tmp/pocket-internet-service
```

Prove cleanup worked:

```sh
if ip netns list | grep -E '^(pocket-as1|pocket-as2|pocket-as3|pocket-as4)( |$)'; then
  echo 'leftover Pocket Internet namespaces found'
  exit 1
fi
echo 'no Pocket Internet namespaces remain'
```

Confirm the public default path still uses the normal host route:

```sh
ip route get 1.1.1.1
```

## What You Can Now Explain

You can now explain:

- why a route and a service listener are separate requirements,
- why binding to `127.0.0.1` is different from binding to a service loopback,
- how to prove a listener's address and port with `ss`,
- how to fetch application data across BGP-learned routes,
- why the return path matters for services,
- why service logs can prove the source address that reached the application.

## Still Okay If Fuzzy

It is okay if these are still fuzzy:

- host-to-lab access,
- firewall rules around services,
- persistent service supervision,
- DNS names for services,
- TLS or application-layer security.

Those are real operational topics, but this chapter needs only one payoff: Pocket Internet can carry useful traffic.

## Next We Need

The next Pocket Internet step is to replace one veth link with WireGuard.

That should feel less strange now. A link can be virtual, local, encrypted, or remote. The routing question remains:

> Which prefixes are reachable, and which path carries packets to the service?
