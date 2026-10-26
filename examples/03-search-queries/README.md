# 03 — Search Queries: Match, Geo Filter, Aggregations

**Design-only — gate 1 target. Not runtime-validated.** This pattern
queries the index from pattern 02 three ways: a match query, a
geo-bounding-box filter, and a terms aggregation. The three queries
cover the three questions a catalog or API asks an index: "find this,"
"find things here," and "summarize what is here."

## Prerequisites

- Elasticsearch 8.19.13 single-node running (pattern 01), localhost:9200
- Pattern 02's `places-idx` with the three synthetic documents
- `curl`

## Files

- `queries.sh` — runs all three queries and prints hit counts

## Steps

```bash
bash queries.sh
```

## Expected output

- Match on title "Synthetic Place Alpha" → exactly 1 hit (`syn-1`).
- Geo-bounding-box filter (top_left lat 0.5 / lon -0.5, bottom_right
  lat -0.5 / lon 0.5) → 3 hits: all three synthetic docs sit inside
  the box by construction.
- Terms aggregation on `kind` → one bucket, key `synthetic`, doc_count 3.
- A match on a title that exists nowhere → 0 hits with HTTP 200 — an
  empty result is a successful query, not an error.

## Failure behavior

- Querying a missing field → 400 with an error type naming the field;
  the query is wrong, not the index.
- Geo filter with swapped corners (top_left below bottom_right) → 400
  or 0 hits depending on version; the pattern's corners are written
  correctly by construction, and a 0-hit geo result must be re-checked
  against the corner order before being believed.
- Aggregation on a `text` field → fielddata error; aggregations need
  `keyword` (or fielddata enabled deliberately) — pattern 02 maps
  `kind` as `keyword` for exactly this reason.
- To confirm at validation: the fleet's exact 8.19.13 response shapes
  for these three queries (stable 8.x surface, unproven against the
  fleet).

## Versions note

Elasticsearch 8.19.13 per the fleet seed. Query DSL shapes are the 8.x
REST surface. All test data is synthetic (pattern 02).
