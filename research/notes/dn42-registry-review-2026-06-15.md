# DN42 Registry README and Schema Review

Reviewed on: 2026-06-15

Primary sources:

- `dn42-registry`: https://git.dn42.dev/dn42/registry
- `dn42-registry-authentication`: https://dn42.cc/wiki/howto/registry-authentication/
- `dn42-getting-started`: https://dn42.cc/wiki/howto/getting-started/

Registry checkout reviewed:

- Commit: `c88548aa5369fefcea8cc484567aa89575dad57f`
- Commit date: 2026-06-15 20:02:01 +0000
- Subject: `Merge pull request 'Adding DNS servers' (#6715) from Paternot/registry:master into master`
- Local ignored cache: `research/cache/dn42-registry/`

## What This Review Covers

This note records the current registry onboarding workflow, schema-required fields, and local validation commands needed before drafting the first registry chapter. It is not a substitute for a live availability check before a real allocation or before publishing final commands.

Use this source set for:

- The registry pull request workflow.
- Object types and schema-required fields.
- Local formatting, schema, and policy validation commands.
- Maintainer authentication and signed commit requirements.
- Privacy warnings attached to registry data.

Do not use this source set alone for:

- Current free ASN or prefix availability.
- Peer-specific policy.
- BIRD or WireGuard configuration.
- Final examples without rerunning the registry tools against a real or fixture branch.

## Required Objects for a First Node

For a first individual IPv6-only node that will announce its own prefix, the minimum practical object set is:

- `mntner`: maintainer object in `data/mntner/`.
- `person`: contact object in `data/person/`.
- `aut-num`: DN42 ASN object in `data/aut-num/`.
- `inet6num`: IPv6 allocation object in `data/inet6num/`.
- `route6`: IPv6 route origin object in `data/route6/`.

Add these when the scenario requires them:

- `inetnum`: IPv4 allocation object in `data/inetnum/`, if the node will use DN42 IPv4.
- `route`: IPv4 route origin object in `data/route/`, if the node will announce DN42 IPv4.
- `dns`: forward DNS object in `data/dns/`, if registering a DN42 domain.
- `organisation`: organisation object in `data/organisation/`, if registering on behalf of a group rather than as an individual.
- `key-cert`: public-key certificate object in `data/key-cert/`, only when using a key-cert based auth path rather than an inline SSH key or Gitea/keyserver PGP key.

Schema-required fields for the first-node path:

| Object | Required fields |
| --- | --- |
| `mntner` | `mntner`, `mnt-by`, `source` |
| `person` | `person`, `nic-hdl`, `mnt-by`, `source` |
| `aut-num` | `aut-num`, `as-name`, `mnt-by`, `source` |
| `inet6num` | `inet6num`, `cidr`, `netname`, `source` |
| `route6` | `route6`, `mnt-by`, `origin`, `source` |
| `inetnum` | `inetnum`, `cidr`, `netname`, `source` |
| `route` | `route`, `mnt-by`, `origin`, `source` |
| `dns` | `domain`, `nserver`, `mnt-by`, `source` |
| `organisation` | `organisation`, `org-name`, `mnt-by`, `source` |
| `key-cert` | `key-cert`, `method`, `owner`, `fingerpr`, `certif`, `mnt-by`, `source` |

Practical requirements beyond schema:

- Add `mnt-by: <FOO>-MNT` to owned objects where the schema permits it, so later edits are authorized by the maintainer.
- Add `admin-c` and `tech-c` references on resource objects in teaching examples, even where the schema marks them optional.
- Add a route object for any announced prefix. The getting-started guide warns that skipped route objects will probably be filtered by major peers because route objects feed route origin authorization checks.
- Use a randomly generated RFC 4193-style ULA prefix for `inet6num`; the registry README explicitly calls this out.

## Required Validation Commands

Run these from a local checkout of a forked registry branch before opening or updating a pull request:

```sh
./fmt-my-stuff <FOO>-MNT
./check-my-stuff <FOO>-MNT
./check-pol origin/master <FOO>-MNT
```

Command purposes:

- `fmt-my-stuff <FOO>-MNT`: fixes minor registry object formatting.
- `check-my-stuff <FOO>-MNT`: validates the maintainer object and objects related to the maintainer against the local schema.
- `check-pol origin/master <FOO>-MNT`: checks policy for changed registry objects compared with the base commit or ref.
- `check-remote GIT-USER GIT-BRANCH USER-MNT`: helper for checking a remote branch after fetching and merging it into the local checkout.
- `squash-my-commits -S --push`: helper for rebasing, squashing, signing, and pushing final PR commits.
- `sign-my-commit`: helper for signing commits when the chosen auth path requires it, especially SSH signing fallback flows.

Useful execution notes:

- `check-my-stuff` and `check-pol` accept `REGDIR=path/to/registry` when the scripts cannot determine the registry directory.
- `check-my-stuff --all` validates the full registry tree.
- `DN42REG_NO_COLOR=1` can make validation output easier to capture in deterministic lesson transcripts.
- The `origin/master` argument in `check-pol origin/master <FOO>-MNT` assumes the local fork and remotes are arranged so that `origin/master` is the intended comparison point. The book should explain the base ref explicitly instead of copying the placeholder blindly.

## Privacy Warnings

The registry README and getting-started guide both require a strong warning:

- Registry data includes personal information and is visible to registered members.
- Anyone with repository access can copy, process, and transfer registry data.
- Treat submitted registry data as public.
- Personal information is optional and voluntary.
- Git history means later deletion or full removal may be technically impossible after data has propagated.
- If public exposure is unacceptable, do not upload personal details.
- Use DN42-specific anonymous contact details or omit optional contact fields instead of inventing bogus contact details.
- Do not clone or mirror the registry into a commercial git repository.

## Authentication Warnings

The `MNTNER-SCHEMA` marks `auth` as optional, but the operational workflow requires an auth method for a usable maintainer. Teach this as required for first-node registration.

Preferred auth paths:

- GPG or PGP: add `auth: pgp-fingerprint <fingerprint>` with the full 40-digit fingerprint and sign with `git commit -S`.
- SSH: add `auth: ssh-<keytype> <pubkey>`, preferably with `ssh-ed25519`, configure Git SSH signing, and sign with `git commit -S`.

Operational warnings:

- Add the GPG or SSH key to the Gitea account when possible so Gitea can verify signed commits automatically.
- Squash multiple commits into one final commit before PR review.
- Sign the final commit with the maintainer auth method.
- If a PR needs updates, rebase, squash, sign, and push the updated branch again.
- Do not use the Gitea web editor for registry object changes; it creates hard-to-review commit history and prevents local script validation.
- Manual signature comments are fallback paths only, not the preferred teaching path.

## Open Questions Before Chapter Drafting

- Decide whether the book teaches SSH Ed25519 signing as the default path, with PGP as an alternative.
- Build a local fixture branch with example first-node objects and run the registry commands end to end.
- Verify current ASN and prefix availability immediately before writing allocation exercises.
- Confirm whether examples should include optional email/contact fields or use a privacy-preserving default.
