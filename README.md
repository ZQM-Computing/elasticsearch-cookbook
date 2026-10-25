# Elasticsearch Cookbook

<!-- ZQM-START -->
<!-- markdownlint-disable MD033 -->
<p align="center">
  <strong>ZQM Computing — Geospatial Engineering & Scientific Computing</strong><br>
  <a href="https://github.com/ZQM-Computing">ZQM Computing</a>
</p>
<!-- markdownlint-enable MD033 -->
<!-- ZQM-END -->

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A **Elasticsearch cookbook** for single-node indices, mappings, and geo search. Patterns are drawn from the ZQM fleet's Elasticsearch 8.19.13 installs (single-node, 1g heap, xpack disabled) on Node-3 and Node-4, where GeoNetwork proved index-level connectivity. It is intended for Engineers who run a local search index behind a catalog or API. Validate each pattern against your own data, software versions, and operating environment before adopting it.

## Repository role and status

**Status:** Active, public — seeding. Pattern passes land in follow-up work from fleet-verified setups; the tables below list what is planned, not what is already written.

**What this repository is:** Elasticsearch patterns — see the table below.

**What it contributes:** Part of the ZQM Computing geospatial portfolio. The umbrella index for the series is [geospatial-cookbooks](https://github.com/ZQM-Computing/geospatial-cookbooks).

**Standing:** This repository is maintained independently. Automated checks cover only the paths and environments configured in its workflows; they do not establish production readiness or operational certification.

## Who this is for

Engineers who run a local search index behind a catalog or API.

## Prerequisites

- Elasticsearch 8.19.13 (single-node)
- Java runtime as bundled
- Bash or PowerShell for the HTTP passes

## Patterns (planned)

| # | Example | What it will demonstrate |
|---|---------|--------------------------|
| 01 | `01-single-node` | Single-node setup: heap, discovery, and security-disabled dev configuration |
| 02 | `02-index-mapping` | Creating indices and mappings, including geo_point fields |
| 03 | `03-search-queries` | Search, filter, and aggregation queries |
| 04 | `04-geonetwork-pairing` | Pairing with GeoNetwork's gn-records, gn-features, and gn-searchlogs indices |

## Repository layout

```text
elasticsearch-cookbook/
├── examples/          # pattern passes, landing in follow-up work
├── README.md
└── LICENSE
```

## Roadmap

- First pattern pass: the first two table rows
- Second pass: the remaining rows, from fleet-verified setups

## Contributing

A contributing guide lands with the first pattern pass. Report security issues to <zqmcomputing@gmail.com> — please do not open a public issue for those.

## More from this series

- [geonetwork-cookbook](https://github.com/ZQM-Computing/geonetwork-cookbook) — Spatial metadata catalogs, harvesting, and CSW search
- [pgstac-cookbook](https://github.com/ZQM-Computing/pgstac-cookbook) — STAC catalogs in PostGIS, stac-fastapi APIs, bulk ingest
- [stac-cookbook](https://github.com/ZQM-Computing/stac-cookbook) — STAC catalog creation, item validation, search API, bulk ops
