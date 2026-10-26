#!/usr/bin/env bash
# Inspect GeoNetwork's Elasticsearch indices and search for the synthetic record.
# Design-only: confirm the ES bind and gn-records mapping on the target host.
# Scope: Node-3 and Node-4 only — Node-1 GeoNetwork has NO Elasticsearch.
set -euo pipefail

: "${ES_BASE:=http://localhost:9200}"
BASE="${ES_BASE%/}"
UUID="00000000-0000-4000-8000-000000000001"

echo "-- gn-* indices --"
curl --fail-with-body --silent --show-error "$BASE/_cat/indices/gn-*?v"
echo
echo "-- per-index counts --"
for idx in gn-records gn-features gn-searchlogs; do
  echo -n "$idx: "
  curl --fail-with-body --silent --show-error "$BASE/$idx/_count"
  echo
done
echo "-- search gn-records for the synthetic uuid --"
curl --fail-with-body --silent --show-error \
  --header "Content-Type: application/json" \
  --data-binary "{\"query\":{\"term\":{\"uuid\":\"$UUID\"}}}" \
  "$BASE/gn-records/_search?size=1"
echo
echo "Expected: all three gn-* indices open; the synthetic UUID found"
echo "after insert + index refresh/rebuild. Confirm the actual UUID field"
echo "and document shape against the installed GeoNetwork build first."
