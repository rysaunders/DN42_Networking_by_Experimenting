# Building a Small Internet

Pocket Internet is a hands-on book/site project for learning networking by building, breaking, observing, and explaining a small Internet on one Linux machine.

The project eventually uses DN42 as the bridge from the local laboratory to a living routing ecosystem. It is not a DN42 setup cookbook; the goal is to understand the routing ideas well enough that real network configuration has a clear reason behind it.

The canonical planning document is [PROJECT_PLAN.md](PROJECT_PLAN.md).

## Current Project State

This repository is in v0.1 hardening. The first milestone focuses on the Pocket Internet foundation: route-selection labs, BIRD/BGP inside the lab, WireGuard link mechanics, and safe DN42 border preparation.

## Operating Model

- Publish with MkDocs Material.
- Host with GitHub Pages.
- Track work with GitHub Issues and milestones.
- Keep source metadata and research notes in `research/`.
- Keep bulky downloaded reference material in ignored local cache files under `research/cache/`.

## Immediate Commands

Run the lab environment preflight from the repository root inside Linux before starting namespace labs:

```sh
./scripts/preflight_lab_env.sh
```

Lab scripts write local transcripts under the ignored `experiments/transcripts/local/` directory by default. To intentionally refresh a checked-in validation transcript, set `LAB_TRANSCRIPT_PATH` to the exact tracked path before running the script.

Build the site strictly:

```sh
uv run mkdocs build --strict
```

Validate the source registry:

```sh
python3 scripts/validate_sources.py
```

Preview the site locally:

```sh
uv run mkdocs serve
```

Fetch local reference cache files:

```sh
python3 scripts/fetch_references.py
```

The raw cache and `research/cache/manifest.json` are ignored by Git. The source of truth remains `research/sources.yml` plus tracked research notes.

Show the planned first issues:

```sh
cat project/backlog.yml
```
