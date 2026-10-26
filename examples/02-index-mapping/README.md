# 02 — Index Mapping: Indices, Mappings, and geo_point

**Design-only — gate 1 target. Not runtime-validated.** This pattern
creates an index with an explicit mapping — including a `geo_point`
field for locations — then indexes three synthetic documents and reads
one back. Explicit mappings beat dynamic mapping for geo work: a
`geo_point` field indexed as text or float is a silent data-model bug
that only surfaces at query time.

## Prerequisites

- Elasticsearch 8.19.13 single-node running (pattern 01), localhost:9200
- `curl`
- No real data: all three documents are fictional places with
  coordinates near longitude/latitude zero, labeled synthetic

## Files

- `mapping.json` — index mapping for `places-idx` (keyword title,
  `geo_point` location, date observed, keyword kind)
- `docs.json` — three synthetic documents (bulk format)
- `index.sh` — creates the index, bulk-indexes the docs, refreshes,
  reads one back

## Steps

```bash
bash index.sh
```

## Expected output

- Index creation returns `{"acknowledged": true}`.
- The bulk response reports zero errors and three created documents.
- A GET of one document returns the stored `_source` exactly as
  submitted, with `location` as a `geo_point` (lat/lon object).
- `GET /places-idx/_mapping` shows `location` typed `geo_point` — if it
  shows anything else, the mapping was not applied before indexing and
  the index must be recreated (mappings for existing fields cannot be
  changed in place).

## Failure behavior

- Index already exists → creation returns 400 `resource_already_exists`;
  delete and recreate for a clean run, or use a fresh index name.
- Malformed `geo_point` (e.g. lat/lon swapped outside range) → the bulk
  item fails with a mapper error while siblings succeed; the bulk
  response must be checked per item, not just for HTTP 200.
- Mapping applied after documents exist → field type stays dynamic;
  the fix is recreate-and-reindex, never an in-place mapping edit.
- To confirm at validation: the fleet's exact 8.19.13 mapping response
  shapes (they are stable 8.x surface, but unproven against the fleet).

## Versions note

Elasticsearch 8.19.13 per the fleet seed. Mapping and bulk shapes are
the 8.x REST surface; index name `places-idx` is pattern-local and
never collides with GeoNetwork's `gn-*` indices.
