# Local Reference Cache

This directory is intentionally ignored except for this README.

Use it for local copies of reference material that help authors and agents work without repeatedly searching the web:

- downloaded HTML,
- PDFs,
- WARC files,
- cloned documentation repositories,
- generated search indexes,
- command output from source-refresh scripts.

Do not rely on this directory as the source of truth. Rebuild it from `research/sources.yml` and cite canonical upstream URLs in published chapters.

Run:

```sh
python3 scripts/fetch_references.py
```

The script writes `manifest.json` with one result per source, including source ID, URL, retrieval time, HTTP status when available, SHA-256 for successful fetches, byte count, content type, and cache path. Failed fetches are recorded in the manifest but do not replace existing cache files.
