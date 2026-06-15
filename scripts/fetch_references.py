#!/usr/bin/env python3
"""Fetch ignored local reference cache files from research/sources.yml.

This script intentionally uses only the Python standard library. It parses the
small, predictable source registry used by this project rather than depending
on a general YAML parser during early setup.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import pathlib
import re
import sys
import tempfile
import urllib.error
import urllib.request


ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCES_FILE = ROOT / "research" / "sources.yml"
CACHE_DIR = ROOT / "research" / "cache"
MANIFEST_FILE = CACHE_DIR / "manifest.json"


def parse_sources() -> list[dict[str, str]]:
    sources: list[dict[str, str]] = []
    current: dict[str, str] | None = None

    for raw_line in SOURCES_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue

        id_match = re.match(r"\s*-\s+id:\s*(.+)\s*$", line)
        if id_match:
            if current:
                sources.append(current)
            current = {"id": clean_scalar(id_match.group(1))}
            continue

        field_match = re.match(r"\s+([a-zA-Z0-9_]+):\s*(.+)\s*$", line)
        if current is not None and field_match:
            key = field_match.group(1)
            value = clean_scalar(field_match.group(2))
            current[key] = value

    if current:
        sources.append(current)

    return sources


def clean_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def safe_filename(source_id: str, content_type: str) -> str:
    extension = "bin"
    if "html" in content_type:
        extension = "html"
    elif "text" in content_type or "xml" in content_type:
        extension = "txt"
    elif "pdf" in content_type:
        extension = "pdf"
    return f"{source_id}.{extension}"


def fetch_source(source: dict[str, str]) -> dict[str, object]:
    source_id = source["id"]
    url = source["url"]
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "DN42-Networking-by-Experimenting reference fetcher",
        },
    )

    fetched_at = dt.datetime.now(dt.UTC).isoformat()
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read()
            content_type = response.headers.get("content-type", "application/octet-stream")
            status = response.status
    except urllib.error.HTTPError as error:
        return {
            "id": source_id,
            "url": url,
            "fetched_at": fetched_at,
            "ok": False,
            "status": error.code,
            "error": error.reason,
        }
    except urllib.error.URLError as error:
        return {
            "id": source_id,
            "url": url,
            "fetched_at": fetched_at,
            "ok": False,
            "error": str(error),
        }

    if not 200 <= status < 400:
        return {
            "id": source_id,
            "url": url,
            "fetched_at": fetched_at,
            "ok": False,
            "status": status,
            "error": f"unexpected HTTP status {status}",
        }

    digest = hashlib.sha256(body).hexdigest()
    filename = safe_filename(source_id, content_type)
    output_path = CACHE_DIR / filename
    write_bytes_atomically(output_path, body)

    return {
        "id": source_id,
        "url": url,
        "fetched_at": fetched_at,
        "ok": True,
        "status": status,
        "content_type": content_type,
        "bytes": len(body),
        "sha256": digest,
        "cache_path": str(output_path.relative_to(ROOT)),
    }


def write_bytes_atomically(output_path: pathlib.Path, body: bytes) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "wb",
        delete=False,
        dir=output_path.parent,
        prefix=f".{output_path.name}.",
        suffix=".tmp",
    ) as temporary_file:
        temporary_file.write(body)
        temporary_path = pathlib.Path(temporary_file.name)
    temporary_path.replace(output_path)


def write_text_atomically(output_path: pathlib.Path, text: str) -> None:
    write_bytes_atomically(output_path, text.encode("utf-8"))


def main() -> int:
    if not SOURCES_FILE.exists():
        print(f"missing source registry: {SOURCES_FILE}", file=sys.stderr)
        return 2

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    sources = parse_sources()
    if not sources:
        print("no sources found", file=sys.stderr)
        return 2

    results = []
    for source in sources:
        if "id" not in source or "url" not in source:
            print(f"skipping incomplete source: {source}", file=sys.stderr)
            continue
        print(f"fetching {source['id']} {source['url']}")
        results.append(fetch_source(source))

    manifest = {
        "generated_at": dt.datetime.now(dt.UTC).isoformat(),
        "source_registry": str(SOURCES_FILE.relative_to(ROOT)),
        "results": results,
    }
    write_text_atomically(MANIFEST_FILE, json.dumps(manifest, indent=2, sort_keys=True) + "\n")

    failed = [result for result in results if not result.get("ok")]
    print(f"fetched {len(results) - len(failed)} of {len(results)} sources")
    if failed:
        print("failed sources:", file=sys.stderr)
        for result in failed:
            print(f"- {result['id']}: {result.get('error') or result.get('status')}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
