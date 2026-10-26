#!/usr/bin/env bash
# GeoNetwork pairing checks: gn-* indices, counts, uuid search, one doc sample.
# Design-only: ES bind to confirm at validation (localhost:9200 default).
# Scope: Node-3 and Node-4 only — Node-1 GeoNetwork has NO Elasticsearch.
set -euo pipefail
: "${ES_BASE:=http://localhost:9200}"
UUID="00000000-0000-4000-8000-000000000001"

echo "-- gn-* indices --"
curl -sS "$ES_BASE/_cat/indices/gn-*?v"
echo
echo "-- per-index counts --"
for idx in gn-records gn-features gn-searchlogs; do
  echo -n "$idx: "
  curl -sS "$ES_BASE/$idx/_count"
  echo
done
echo "-- search gn-records for the synthetic uuid --"
curl -sS -H "Content-Type: application/json" -d "{\"query\":{\"term\":{\"uuid\":\"$UUID\"}}}" \
  "$ES_BASE/gn-records/_search?size=1"
echo
echo "Expected: all three gn-* indices open; the synthetic uuid found"
echo "after insert + index rebuild. Document field spellings inside"
echo "gn-records are to confirm at validation — record one real doc shape."
