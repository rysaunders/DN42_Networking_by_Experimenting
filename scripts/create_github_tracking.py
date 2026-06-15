#!/usr/bin/env python3
"""Create GitHub labels, milestones, and seed issues from project YAML files.

The parser is intentionally narrow and supports only the simple YAML shape used
by `project/labels.yml` and `project/backlog.yml`.
"""

from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
LABELS_FILE = ROOT / "project" / "labels.yml"
BACKLOG_FILE = ROOT / "project" / "backlog.yml"
REPO = "rysaunders/DN42_Networking_by_Experimenting"


def clean_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def run_gh(args: list[str], *, input_text: str | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["gh", *args],
        input=input_text,
        text=True,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=check,
    )


def parse_labels() -> list[dict[str, str]]:
    labels: list[dict[str, str]] = []
    current: dict[str, str] | None = None

    for raw_line in LABELS_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        name_match = re.match(r"\s*-\s+name:\s*(.+)\s*$", line)
        if name_match:
            if current:
                labels.append(current)
            current = {"name": clean_scalar(name_match.group(1))}
            continue

        field_match = re.match(r"\s+([a-zA-Z0-9_]+):\s*(.+)\s*$", line)
        if current is not None and field_match:
            current[field_match.group(1)] = clean_scalar(field_match.group(2))

    if current:
        labels.append(current)
    return labels


def parse_backlog() -> tuple[list[dict[str, str]], list[dict[str, object]]]:
    milestones: list[dict[str, str]] = []
    issues: list[dict[str, object]] = []
    section = ""
    current: dict[str, object] | None = None
    body_key: str | None = None
    body_lines: list[str] = []

    def finish_body() -> None:
        nonlocal body_key, body_lines
        if current is not None and body_key:
            current[body_key] = "\n".join(body_lines).rstrip() + "\n"
        body_key = None
        body_lines = []

    def finish_item() -> None:
        nonlocal current
        finish_body()
        if not current:
            return
        if section == "milestones":
            milestones.append({key: str(value) for key, value in current.items()})
        elif section == "issues":
            issues.append(current)
        current = None

    for raw_line in BACKLOG_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            if body_key:
                body_lines.append("")
            continue

        if body_key and (raw_line.startswith("      ") or not raw_line.strip()):
            body_lines.append(raw_line[6:] if raw_line.startswith("      ") else "")
            continue

        if line in {"milestones:", "issues:"}:
            finish_item()
            section = line[:-1]
            continue

        item_match = re.match(r"\s*-\s+title:\s*(.+)\s*$", line)
        if item_match:
            finish_item()
            current = {"title": clean_scalar(item_match.group(1))}
            continue

        field_match = re.match(r"\s+([a-zA-Z0-9_]+):\s*(.*)\s*$", line)
        if current is not None and field_match:
            key = field_match.group(1)
            value = field_match.group(2).strip()
            if value == "|":
                finish_body()
                body_key = key
                body_lines = []
            elif value.startswith("[") and value.endswith("]"):
                current[key] = [
                    clean_scalar(part)
                    for part in value[1:-1].split(",")
                    if part.strip()
                ]
            else:
                current[key] = clean_scalar(value)

    finish_item()
    return milestones, issues


def existing_issue_titles() -> set[str]:
    result = run_gh([
        "issue",
        "list",
        "--repo",
        REPO,
        "--state",
        "all",
        "--limit",
        "200",
        "--json",
        "title",
    ])
    return {item["title"] for item in json.loads(result.stdout)}


def create_or_update_label(label: dict[str, str]) -> None:
    name = label["name"]
    color = label["color"].lstrip("#")
    description = label["description"]

    create = run_gh(
        [
            "label",
            "create",
            name,
            "--repo",
            REPO,
            "--color",
            color,
            "--description",
            description,
        ],
        check=False,
    )
    if create.returncode == 0:
        print(f"created label: {name}")
        return

    edit = run_gh(
        [
            "label",
            "edit",
            name,
            "--repo",
            REPO,
            "--color",
            color,
            "--description",
            description,
        ],
        check=False,
    )
    if edit.returncode != 0:
        print(edit.stderr, file=sys.stderr)
        raise SystemExit(edit.returncode)
    print(f"updated label: {name}")


def ensure_milestone(milestone: dict[str, str]) -> None:
    existing = run_gh([
        "api",
        f"repos/{REPO}/milestones",
        "--jq",
        f".[] | select(.title == \"{milestone['title']}\") | .number",
    ])
    if existing.stdout.strip():
        print(f"milestone exists: {milestone['title']}")
        return

    run_gh([
        "api",
        f"repos/{REPO}/milestones",
        "--method",
        "POST",
        "-f",
        f"title={milestone['title']}",
        "-f",
        f"description={milestone.get('description', '')}",
    ])
    print(f"created milestone: {milestone['title']}")


def create_issue(issue: dict[str, object], existing_titles: set[str]) -> None:
    title = str(issue["title"])
    if title in existing_titles:
        print(f"issue exists: {title}")
        return

    args = [
        "issue",
        "create",
        "--repo",
        REPO,
        "--title",
        title,
        "--body",
        str(issue.get("body", "")),
    ]
    labels = issue.get("labels", [])
    if labels:
        args.extend(["--label", ",".join(str(label) for label in labels)])
    milestone = issue.get("milestone")
    if milestone:
        args.extend(["--milestone", str(milestone)])

    result = run_gh(args)
    print(f"created issue: {title} {result.stdout.strip()}")


def main() -> int:
    for path in [LABELS_FILE, BACKLOG_FILE]:
        if not path.exists():
            print(f"missing required file: {path}", file=sys.stderr)
            return 2

    labels = parse_labels()
    milestones, issues = parse_backlog()

    for label in labels:
        create_or_update_label(label)

    for milestone in milestones:
        ensure_milestone(milestone)

    titles = existing_issue_titles()
    for issue in issues:
        create_issue(issue, titles)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
