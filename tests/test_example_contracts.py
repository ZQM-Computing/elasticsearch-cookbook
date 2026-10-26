import json
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]
EXAMPLES = ROOT / "examples"


class ElasticsearchFixtureContracts(unittest.TestCase):
    def test_mapping_declares_geo_point_and_single_node_settings(self):
        mapping = json.loads((EXAMPLES / "02-index-mapping" / "mapping.json").read_text(encoding="utf-8"))
        settings = mapping["settings"]
        properties = mapping["mappings"]["properties"]
        self.assertEqual(properties["location"]["type"], "geo_point")
        self.assertEqual(settings["number_of_shards"], 1)
        self.assertEqual(settings["number_of_replicas"], 0)

    def test_bulk_fixture_is_valid_ndjson_with_three_unique_synthetic_documents(self):
        lines = (EXAMPLES / "02-index-mapping" / "docs.json").read_text(encoding="utf-8").splitlines()
        self.assertEqual(len(lines), 6)
        actions = [json.loads(lines[index]) for index in (0, 2, 4)]
        documents = [json.loads(lines[index]) for index in (1, 3, 5)]
        self.assertEqual([item["index"]["_id"] for item in actions], ["syn-1", "syn-2", "syn-3"])
        self.assertEqual(len({item["title"] for item in documents}), 3)
        for document in documents:
            self.assertEqual(document["kind"], "synthetic")
            self.assertEqual(set(document["location"]), {"lat", "lon"})

    def test_all_example_json_fixtures_parse(self):
        for path in sorted(EXAMPLES.rglob("*.json")):
            if path.name == "docs.json":
                for line in path.read_text(encoding="utf-8").splitlines():
                    with self.subTest(path=path.relative_to(ROOT), line=line[:60]):
                        json.loads(line)
            else:
                with self.subTest(path=path.relative_to(ROOT)):
                    json.loads(path.read_text(encoding="utf-8"))


class ElasticsearchScriptContracts(unittest.TestCase):
    def test_all_shell_scripts_fail_fast(self):
        scripts = sorted(EXAMPLES.rglob("*.sh"))
        self.assertGreaterEqual(len(scripts), 4)
        for script in scripts:
            with self.subTest(script=script.relative_to(ROOT)):
                self.assertIn("set -euo pipefail", script.read_text(encoding="utf-8"))

    def test_http_scripts_fail_on_http_errors(self):
        for relative in (
            "examples/02-index-mapping/index.sh",
            "examples/03-search-queries/queries.sh",
            "examples/04-geonetwork-pairing/pairing.sh",
        ):
            with self.subTest(script=relative):
                self.assertIn("--fail-with-body", (ROOT / relative).read_text(encoding="utf-8"))

    def test_bulk_index_checks_each_item_not_only_http_status(self):
        script = (EXAMPLES / "02-index-mapping" / "index.sh").read_text(encoding="utf-8")
        self.assertIn('payload.get("errors") is not False', script)
        self.assertIn('len(items) != 3', script)
        self.assertIn('properties.get("location", {}).get("type") != "geo_point"', script)
        self.assertIn('"@$DIR/docs.json"', script)

    def test_search_examples_assert_hit_counts_and_aggregation(self):
        script = (EXAMPLES / "03-search-queries" / "queries.sh").read_text(encoding="utf-8")
        self.assertIn('assert_hits "$TMP_DIR/match.json" 1', script)
        self.assertIn('assert_hits "$TMP_DIR/geo.json" 3', script)
        self.assertIn('assert_hits "$TMP_DIR/empty.json" 0', script)
        self.assertIn('buckets[0].get("doc_count") != 3', script)


if __name__ == "__main__":
    unittest.main()
