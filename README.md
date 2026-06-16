# Building a Small Internet

Networking by Experimenting with DN42 is a hands-on book/site project for learning networking by building, breaking, observing, and explaining a small Internet.

The canonical planning document is [PROJECT_PLAN.md](PROJECT_PLAN.md).

## Current Project State

This repository is in project setup. The first milestone is `v0.1`: Pocket Internet foundation, route-selection labs, BIRD/BGP inside the lab, one WireGuard-replaced lab link, and a safe DN42 border design.

## Operating Model

- Publish with MkDocs Material.
- Host with GitHub Pages.
- Track work with GitHub Issues and milestones.
- Keep source metadata and research notes in `research/`.
- Keep bulky downloaded reference material in ignored local cache files under `research/cache/`.

## Immediate Commands

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
