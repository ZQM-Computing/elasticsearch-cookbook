#!/usr/bin/env bash
# Three queries against pattern 02's places-idx: match, geo filter, aggregation.
# Design-only: assumes pattern 01's single node on localhost:9200.
set -euo pipefail
: "${ES_BASE:=http://localhost:9200}"

echo "-- 1. match on title (expect exactly 1 hit: syn-1) --"
curl -sS -H "Content-Type: application/json" -d '{"query":{"match":{"title":"Synthetic Place Alpha"}}}' \
  "$ES_BASE/places-idx/_search"
echo
echo "-- 2. geo_bounding_box filter (expect 3 hits: all synthetic docs) --"
curl -sS -H "Content-Type: application/json" -d '{"query":{"bool":{"filter":{"geo_bounding_box":{"location":{"top_left":{"lat":0.5,"lon":-0.5},"bottom_right":{"lat":-0.5,"lon":0.5}}}}}}}' \
  "$ES_BASE/places-idx/_search"
echo
echo "-- 3. terms aggregation on kind (expect one bucket: synthetic = 3) --"
curl -sS -H "Content-Type: application/json" -d '{"size":0,"aggs":{"by_kind":{"terms":{"field":"kind"}}}}' \
  "$ES_BASE/places-idx/_search"
echo
echo "-- 4. empty result (expect 0 hits, HTTP 200 — not an error) --"
curl -sS -H "Content-Type: application/json" -d '{"query":{"match":{"title":"No Such Place Anywhere"}}}' \
  "$ES_BASE/places-idx/_search"
echo
