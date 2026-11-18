import json
import tempfile
import unittest
from pathlib import Path

from pipeline.etl import process_pages, run


def entry(id="X", updated_at="2026-01-02T09:00:00Z", status="open", channel="chat"):
    return dict(id=id, updated_at=updated_at, status=status, channel=channel, category="query")


class PipelineTests(unittest.TestCase):
    def test_latest_revision_wins(self):
        old = entry()
        new = entry(updated_at="2026-01-03T09:00:00Z", status="closed")
        r = process_pages([{"page": 1, "records": [old]}, {"page": 2, "records": [new]}])
        self.assertEqual(r["records"][0]["status"], "closed")
        self.assertEqual(r["quality"]["accepted_distinct_ids"], 1)

    def test_page_order_does_not_change_curated_records(self):
        p = [{"page": 1, "records": [entry("A"), entry("B")]}, {"page": 2, "records": [entry("A", status="closed")]}]
        self.assertEqual(process_pages(p)["records"], process_pages(p[::-1])["records"])

    def test_invalid_record_quarantined(self):
        r = process_pages([{"page": 1, "records": [entry(), {"id": "BROKEN"}]}])
        self.assertEqual(r["quality"]["rejected_rows"], 1)
        self.assertEqual(len(r["records"]), 1)

    def test_unknown_enum_quarantined(self):
        r = process_pages([{"page": 1, "records": [entry(channel="fax")]}])
        self.assertEqual(r["quality"]["rejected_rows"], 1)

    def test_invalid_timestamp_quarantined(self):
        r = process_pages([{"page": 1, "records": [entry(updated_at="2026-14-45T09:00:00Z")]}])
        self.assertEqual(len(r["quarantine"]), 1)

    def test_duplicate_page_rejected(self):
        with self.assertRaisesRegex(ValueError, "duplicate page"):
            process_pages([{"page": 1, "records": []}, {"page": 1, "records": []}])

    def test_summary_matches_curated_records(self):
        r = process_pages([{"page": 1, "records": [entry("A"), entry("B", status="closed")]}])
        self.assertEqual(sum(x["count"] for x in r["summary"]), 2)

    def test_file_roundtrip(self):
        with tempfile.TemporaryDirectory() as d:
            destination = Path(d) / "out"
            r = run(Path("data/fictional_pages.json"), destination)
            self.assertEqual(r["quality"]["accepted_distinct_ids"], 4)
            self.assertEqual(r["quality"]["rejected_rows"], 1)
            for name in ("records", "summary", "quality", "quarantine"):
                self.assertEqual(json.loads((destination / (name + ".json")).read_text()), r[name])


if __name__ == "__main__":
    unittest.main()
