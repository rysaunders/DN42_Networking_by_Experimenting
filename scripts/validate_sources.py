#!/usr/bin/env python3
"""Validate the research source registry.

The source registry deliberately uses a small, predictable YAML shape. This
validator keeps early project setup dependency-free while still producing
source-specific errors that are useful in CI.
"""

from __future__ import annotations

import datetime as dt
import pathlib
import re
import sys
import urllib.parse


ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCES_FILE = ROOT / "research" / "sources.yml"

REQUIRED_FIELDS = {
    "id",
    "title",
    "url",
    "category",
    "authority",
    "volatility",
    "reviewed_on",
    "cache_policy",
    "status",
    "notes",
}

ALLOWED_CACHE_POLICIES = {
    "ignored-raw-cache",
    "tracked-small-snapshot-allowed",
}

ALLOWED_STATUSES = {
    "recommended-stack",
    "research-required",
    "reviewed-for-planning",
}

ALLOWED_VOLATILITY = {
    "low",
    "medium",
    "high",
}

ALLOWED_AUTHORITIES = {
    "community",
    "manual",
    "official",
    "standards",
}

SOURCE_ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")


def clean_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_sources() -> list[dict[str, str]]:
    sources: list[dict[str, str]] = []
    current: dict[str, str] | None = None

    for line_number, raw_line in enumerate(SOURCES_FILE.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.rstrip()
        if not line.strip() or line.lstrip().startswith("#") or line == "sources:":
            continue

        id_match = re.match(r"\s*-\s+id:\s*(.+)\s*$", line)
        if id_match:
            if current:
                sources.append(current)
            current = {
                "id": clean_scalar(id_match.group(1)),
                "_line": str(line_number),
            }
            continue

        field_match = re.match(r"\s+([a-zA-Z0-9_]+):\s*(.+)\s*$", line)
        if current is not None and field_match:
            key = field_match.group(1)
            current[key] = clean_scalar(field_match.group(2))
            continue

        source_id = current.get("id", "registry") if current else "registry"
        raise ValueError(f"{source_id}: unsupported sources.yml syntax at line {line_number}: {line}")

    if current:
        sources.append(current)

    return sources


def validate_url(source_id: str, url: str) -> list[str]:
    errors: list[str] = []
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        errors.append(f"{source_id}: url must use http or https: {url}")
    if not parsed.netloc:
        errors.append(f"{source_id}: url must include a host: {url}")
    if any(character.isspace() for character in url):
        errors.append(f"{source_id}: url must not contain whitespace: {url}")
    return errors


def validate_review_date(source_id: str, reviewed_on: str) -> list[str]:
    try:
        dt.date.fromisoformat(reviewed_on)
    except ValueError:
        return [f"{source_id}: reviewed_on must be YYYY-MM-DD: {reviewed_on}"]
    return []


def validate_source(source: dict[str, str]) -> list[str]:
    source_id = source.get("id", f"source-at-line-{source.get('_line', 'unknown')}")
    errors: list[str] = []

    missing_fields = sorted(REQUIRED_FIELDS - source.keys())
    for field in missing_fields:
        errors.append(f"{source_id}: missing required field: {field}")

    if "id" in source and not SOURCE_ID_PATTERN.fullmatch(source["id"]):
        errors.append(f"{source_id}: id must be lowercase kebab-case")

    for field in REQUIRED_FIELDS & source.keys():
        if not source[field].strip():
            errors.append(f"{source_id}: {field} must not be empty")

    if "url" in source:
        errors.extend(validate_url(source_id, source["url"]))

    if "reviewed_on" in source:
        errors.extend(validate_review_date(source_id, source["reviewed_on"]))

    if "cache_policy" in source and source["cache_policy"] not in ALLOWED_CACHE_POLICIES:
        allowed = ", ".join(sorted(ALLOWED_CACHE_POLICIES))
        errors.append(f"{source_id}: cache_policy must be one of: {allowed}")

    if "status" in source and source["status"] not in ALLOWED_STATUSES:
        allowed = ", ".join(sorted(ALLOWED_STATUSES))
        errors.append(f"{source_id}: status must be one of: {allowed}")

    if "volatility" in source and source["volatility"] not in ALLOWED_VOLATILITY:
        allowed = ", ".join(sorted(ALLOWED_VOLATILITY))
        errors.append(f"{source_id}: volatility must be one of: {allowed}")

    if "authority" in source and source["authority"] not in ALLOWED_AUTHORITIES:
        allowed = ", ".join(sorted(ALLOWED_AUTHORITIES))
        errors.append(f"{source_id}: authority must be one of: {allowed}")

    return errors


def validate_sources(sources: list[dict[str, str]]) -> list[str]:
    errors: list[str] = []
    seen_ids: dict[str, str] = {}

    if not sources:
        return ["registry: no sources found"]

    for source in sources:
        source_id = source.get("id", f"source-at-line-{source.get('_line', 'unknown')}")
        if source_id in seen_ids:
            errors.append(f"{source_id}: duplicate id first seen at line {seen_ids[source_id]}")
        else:
            seen_ids[source_id] = source.get("_line", "unknown")
        errors.extend(validate_source(source))

    return errors


def main() -> int:
    if not SOURCES_FILE.exists():
        print(f"registry: missing source registry: {SOURCES_FILE}", file=sys.stderr)
        return 2

    try:
        sources = parse_sources()
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1

    errors = validate_sources(sources)
    if errors:
        print("source registry validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"source registry ok: {len(sources)} sources")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
