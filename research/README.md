# Research Material Policy

This directory stores source metadata, research notes, and carefully selected snapshots for the DN42 networking book/site.

The goal is to make research reproducible without turning the repository into an unreviewed mirror of third-party documentation.

## What Is Tracked

- `sources.yml`: canonical source registry.
- `notes/`: source reviews, extracted facts, command provenance, and open questions.
- `snapshots/`: small text snapshots of volatile sources when a retrieval date matters.

## What Is Ignored

- `cache/`: raw downloaded HTML, PDFs, WARC files, cloned documentation repositories, generated indexes, and other bulky local material.

Raw cache files are for local authoring and agent context. They should be reproducible from `sources.yml` and scripts, not treated as canonical project content.

## Rules

- Cite canonical URLs in chapters.
- Keep retrieval dates for DN42-current practice.
- Track summaries and small excerpts, not wholesale copies, unless the source license clearly permits redistribution and the project has a reason to vendor it.
- Mark volatile operational guidance as `dn42-current`.
- Refresh `dn42-current` notes before each release.
