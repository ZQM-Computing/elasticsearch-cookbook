#!/usr/bin/env bash
# Create places-idx, bulk-index three synthetic docs, read one back.
# Design-only: assumes pattern 01's single node on localhost:9200.
set -euo pipefail
: "${ES_BASE:=http://localhost:9200}"

echo "-- create index --"
curl -sS -X PUT -H "Content-Type: application/json" --data-binary @mapping.json \
  "$ES_BASE/places-idx"
echo
echo "-- bulk index (check per-item errors, not just HTTP 200) --"
curl -sS -X POST -H "Content-Type: application/x-ndjson" --data-binary @docs.json \
  "$ES_BASE/places-idx/_bulk?refresh=true"
echo
echo "-- read one back --"
curl -sS "$ES_BASE/places-idx/_doc/syn-1"
echo
echo "-- mapping proof --"
curl -sS "$ES_BASE/places-idx/_mapping"
echo
echo "Expected: acknowledged true, 3 created, location typed geo_point."
