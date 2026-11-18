"""Deterministic pipeline for synthetic paginated operational records."""
from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path

REQUIRED = {"id", "updated_at", "channel", "status", "category"}
CHANNELS = {"email", "chat", "web"}
STATUSES = {"open", "closed"}


def _validate(item: object) -> dict:
    if not isinstance(item, dict) or not REQUIRED <= item.keys():
        raise ValueError("missing required fields")
    if not all(isinstance(item[k], str) and item[k].strip() for k in REQUIRED):
        raise ValueError("required fields must be non-empty strings")
    if item["channel"] not in CHANNELS or item["status"] not in STATUSES:
        raise ValueError("unrecognised channel or status")
    if not (len(item["updated_at"]) == 20 and item["updated_at"].endswith("Z")):
        raise ValueError("updated_at must use UTC ISO-8601 second precision")
    from datetime import datetime
    try:
        datetime.strptime(item["updated_at"], "%Y-%m-%dT%H:%M:%SZ")
    except ValueError as exc:
        raise ValueError("invalid timestamp") from exc
    return {k: item[k].strip() for k in sorted(REQUIRED)}


def process_pages(pages: list[dict]) -> dict:
    """Select latest version per ID; quarantine malformed records.

    Input page: {'page': int, 'records': [object, ...]}. Identical
    timestamps resolve by canonical field values, independently of input order.
    """
    valid: dict[str, dict] = {}
    rejected = []
    seen_pages = set()
    for page in pages:
        if not isinstance(page, dict) or not isinstance(page.get("page"), int) or isinstance(page.get("page"), bool) or not isinstance(page.get("records"), list):
            raise ValueError("invalid page envelope")
        if page["page"] in seen_pages:
            raise ValueError("duplicate page number")
        seen_pages.add(page["page"])
        for index, item in enumerate(page["records"]):
            try:
                row = _validate(item)
            except ValueError as exc:
                rejected.append({"page": page["page"], "position": index, "reason": str(exc)})
                continue
            old = valid.get(row["id"])
            key = lambda r: (r["updated_at"], tuple(r[k] for k in sorted(REQUIRED)))
            if old is None or key(row) > key(old):
                valid[row["id"]] = row
    records = sorted(valid.values(), key=lambda r: r["id"])
    counts = Counter((r["channel"], r["status"]) for r in records)
    summary = [{"channel": channel, "status": status, "count": count}
               for (channel, status), count in sorted(counts.items())]
    return {"records": records,
            "summary": summary,
            "quality": {"pages": len(pages), "accepted_distinct_ids": len(records),
                        "rejected_rows": len(rejected)},
            "quarantine": sorted(rejected, key=lambda r: (r["page"], r["position"]))}


def run(input_file: Path, output_dir: Path) -> dict:
    pages = json.loads(input_file.read_text(encoding="utf-8"))
    if not isinstance(pages, list):
        raise ValueError("top-level input must be a page list")
    result = process_pages(pages)
    output_dir.mkdir(parents=True, exist_ok=True)
    for name in ("records", "summary", "quality", "quarantine"):
        (output_dir / f"{name}.json").write_text(json.dumps(result[name], indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("data/fictional_pages.json"))
    parser.add_argument("--output", type=Path, default=Path("output"))
    args = parser.parse_args()
    report = run(args.input, args.output)
    print(json.dumps(report["quality"], sort_keys=True))
