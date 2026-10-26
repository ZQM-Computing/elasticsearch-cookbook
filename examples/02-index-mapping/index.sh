#!/usr/bin/env bash
# Create places-idx, bulk-index three synthetic docs, and verify mappings/read-back.
# Design-only: target ES 8.19.13 single-node development instance.
set -euo pipefail

: "${ES_BASE:=http://localhost:9200}"
BASE="${ES_BASE%/}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

request() {
  curl --fail-with-body --silent --show-error "$@"
}

echo "-- create index --"
request --request PUT --header "Content-Type: application/json" \
  --data-binary "@$DIR/mapping.json" --output "$TMP_DIR/create.json" \
  "$BASE/places-idx"
python - "$TMP_DIR/create.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
if payload.get("acknowledged") is not True:
    raise SystemExit(f"Index creation was not acknowledged: {payload}")
print("Index creation acknowledged.")
PY

echo "-- bulk index synthetic docs --"
request --request POST --header "Content-Type: application/x-ndjson" \
  --data-binary "@$DIR/docs.json" --output "$TMP_DIR/bulk.json" \
  "$BASE/places-idx/_bulk?refresh=true"
python - "$TMP_DIR/bulk.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
items = payload.get("items", [])
if payload.get("errors") is not False:
    raise SystemExit(f"Bulk API reported item errors: {payload}")
if len(items) != 3:
    raise SystemExit(f"Expected 3 bulk items, got {len(items)}")
for item in items:
    result = item.get("index", {})
    if result.get("status") not in (200, 201) or result.get("error"):
        raise SystemExit(f"Bulk item failed: {item}")
if any(item.get("index", {}).get("status") not in (200, 201) for item in items):
    raise SystemExit(f"Unexpected bulk item status: {items}")
print("Bulk contract passed: 3 documents indexed (create or update), errors=false.")
PY

echo "-- read one back --"
request "$BASE/places-idx/_doc/syn-1" --output "$TMP_DIR/document.json"
python - "$TMP_DIR/document.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
source = payload.get("_source", {})
if payload.get("found") is not True or source.get("title") != "Synthetic Place Alpha":
    raise SystemExit(f"Unexpected document read-back: {payload}")
print(f"Read-back verified: {payload['_id']} — {source['title']}")
PY

echo "-- mapping proof --"
request "$BASE/places-idx/_mapping" --output "$TMP_DIR/mapping-response.json"
python - "$TMP_DIR/mapping-response.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
properties = payload.get("places-idx", {}).get("mappings", {}).get("properties", {})
if properties.get("location", {}).get("type") != "geo_point":
    raise SystemExit(f"Expected location to be geo_point: {properties}")
print("Mapping verified: location is geo_point.")
PY
