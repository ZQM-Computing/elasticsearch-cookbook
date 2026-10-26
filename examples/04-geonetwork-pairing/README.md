# 04 — GeoNetwork Pairing: The gn-* Indices

**Design-only — gate 1 target. Not runtime-validated.** This pattern is
the Elasticsearch half of the GeoNetwork pairing: what the three
`gn-*` indices are, how to confirm GeoNetwork is writing to them, and
how to search `gn-records` for a catalog record. It pairs with
geonetwork-cookbook pattern 04, which covers the same indices from the
GeoNetwork side. The pairing is proven on Node-3 and Node-4; Node-1's
GeoNetwork has no Elasticsearch, so this pattern does not apply there.

## Prerequisites

- Elasticsearch 8.19.13 single-node (pattern 01), localhost:9200
- GeoNetwork 4.4.12 with its Elasticsearch connection configured
  (Node-3 / Node-4 fleet shape)
- `curl`
- A catalog record inserted via GeoNetwork (geonetwork-cookbook
  pattern 01's synthetic record, for the end-to-end check)

## Files

- `pairing.sh` — lists `gn-*` indices, counts docs, searches
  `gn-records` for the synthetic uuid, and samples one document

## Steps

```bash
bash pairing.sh
```

## Expected output

- `_cat/indices/gn-*` lists `gn-records`, `gn-features`, and
  `gn-searchlogs`, all open (fleet evidence: all three open on Node-3
  and Node-4 after the GeoNetwork + Elasticsearch install).
- `gn-records` contains the synthetic record's document after insert
  plus an index rebuild; the search by uuid returns it.
- `gn-features` holds feature-level entries derived from record
  geometries; `gn-searchlogs` holds search-traffic entries. Their exact
  document shapes are GeoNetwork-written and version-specific — see
  "to confirm" below, not asserted here.
- Index health: single-node yellow is correct (see pattern 01); a red
  index means shards unassigned, not "slow search."

## Failure behavior

- `gn-*` indices absent → GeoNetwork's Elasticsearch connection is
  not configured or the index rebuild has not run; the fix is
  configuration + rebuild, not hand-creating indices (hand-created
  mappings diverge from GeoNetwork's).
- Stale search after insert → rebuild pending; search results lag
  inserts by design until the rebuild runs.
- Searching `gn-records` by a field that is not indexed as expected →
  0 hits; field spellings inside GeoNetwork-written documents are the
  first thing to re-check (see below).
- To confirm at validation: the exact document field spellings
  GeoNetwork 4.4.12 writes into `gn-records` (uuid, title, geometry
  fields), the rebuild trigger (UI vs API), and the Elasticsearch bind
  on the fleet (localhost:9200 default assumed here).

## Versions note

GeoNetwork 4.4.12 + Elasticsearch 8.19.13 per the fleet seed. Index
names are fleet-verified (Node-3/Node-4). Document internals are
deliberately NOT asserted: they are GeoNetwork-written and the
validation run must read one real (synthetic-record) document and
record its shape.
