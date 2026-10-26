#!/usr/bin/env bash
# Four assertions against pattern 02's places-idx: match, geo filter, aggregation, empty result.
# Design-only: assumes pattern 01 has created the index on the target ES instance.
set -euo pipefail

: "${ES_BASE:=http://localhost:9200}"
BASE="${ES_BASE%/}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

request() {
  local name="$1"
  local body="$2"
  local output="$3"
  curl --fail-with-body --silent --show-error \
    --header "Content-Type: application/json" \
    --data-binary "$body" --output "$output" "$BASE/places-idx/_search"
}

assert_hits() {
  local file="$1" expected="$2" label="$3"
  python - "$file" "$expected" "$label" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
expected = int(sys.argv[2])
actual = payload.get("hits", {}).get("total", {}).get("value")
if actual != expected:
    raise SystemExit(f"{sys.argv[3]}: expected {expected} hits, got {actual}; response={payload}")
print(f"PASS {sys.argv[3]}: {actual} hits")
PY
}

echo "-- 1. match on title (expect exactly 1 hit: syn-1) --"
request match '{"query":{"match":{"title":"Synthetic Place Alpha"}}}' "$TMP_DIR/match.json"
assert_hits "$TMP_DIR/match.json" 1 "title match"

echo "-- 2. geo_bounding_box filter (expect 3 hits) --"
request geo '{"query":{"bool":{"filter":{"geo_bounding_box":{"location":{"top_left":{"lat":0.5,"lon":-0.5},"bottom_right":{"lat":-0.5,"lon":0.5}}}}}}}' "$TMP_DIR/geo.json"
assert_hits "$TMP_DIR/geo.json" 3 "geo bounding box"

echo "-- 3. terms aggregation on kind (expect one bucket: synthetic = 3) --"
request aggregation '{"size":0,"aggs":{"by_kind":{"terms":{"field":"kind"}}}}' "$TMP_DIR/aggregation.json"
python - "$TMP_DIR/aggregation.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
buckets = payload.get("aggregations", {}).get("by_kind", {}).get("buckets", [])
if len(buckets) != 1 or buckets[0].get("key") != "synthetic" or buckets[0].get("doc_count") != 3:
    raise SystemExit(f"Unexpected aggregation buckets: {buckets}")
print("PASS aggregation: synthetic=3")
PY

echo "-- 4. empty result (expect zero hits, HTTP 200) --"
request empty '{"query":{"match":{"title":"No Such Place Anywhere"}}}' "$TMP_DIR/empty.json"
assert_hits "$TMP_DIR/empty.json" 0 "empty query"
