# Building a Small Internet

Networking by Experimenting with DN42 is a hands-on book/site project for learning networking by building, breaking, observing, and explaining a small Internet.

The canonical planning document is [PROJECT_PLAN.md](PROJECT_PLAN.md).

## Current Project State

This repository is in project setup. The first milestone is `v0.1`: zero to one safe DN42 peer, split DNS, and first service access.

## Operating Model

- Publish with MkDocs Material.
- Host with GitHub Pages.
- Track work with GitHub Issues and milestones.
- Keep source metadata and research notes in `research/`.
- Keep bulky downloaded reference material in ignored local cache files under `research/cache/`.

## Immediate Commands

Fetch local reference cache files:

```sh
python3 scripts/fetch_references.py
```

Show the planned first issues:

```sh
cat project/backlog.yml
```
