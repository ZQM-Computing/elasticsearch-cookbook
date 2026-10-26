# 01 — Single Node: Dev Configuration and Health

**Design-only — gate 1 target. Not runtime-validated.** This pattern
stands up Elasticsearch as a single node for development: discovery,
heap, and the security-disabled configuration the fleet runs, plus the
health check that proves the node is up. Single-node means no replicas
and no failover — the yellow health status below is the correct,
expected outcome, not a problem to fix.

## Prerequisites

- Elasticsearch 8.19.13 (single-node) — fleet seed version
- Java runtime as bundled with Elasticsearch
- `curl`
- A dev-only machine: this configuration disables security and must
  never be exposed beyond localhost (see the warning below)

## Files

- `elasticsearch.yml` — single-node configuration (localhost bind,
  single-node discovery, security disabled)
- `jvm.options` — 1g heap (fleet: 1g heap)
- `start.sh` — starts the node and waits for the health check

## Steps

```bash
bash start.sh
```

## Expected output

- `GET /` returns the node name, cluster name, and version 8.19.13.
- `GET /_cluster/health` returns `"status": "yellow"` — yellow is
  correct for a single node (replica shards have nowhere to go).
  Green on a single node would mean replicas were disabled, which is a
  different configuration, not a better one.
- `GET /_cat/nodes?v` lists exactly one node.

## Failure behavior

- Port already in use (9200) → the node fails to bind and exits; the
  fix is to stop the existing node, not to move the port silently.
- Heap over available memory → the JVM fails at startup; the 1g heap
  here is the fleet's value, not a recommendation for large indices.
- **Dev-only warning (standing): `xpack.security.enabled=false` is the
  fleet's dev configuration. Auth enablement is a follow-up decision,
  not part of this pattern. Never bind this configuration to a public
  interface, never ship it as a production setup, and never present it
  as secure. The pattern's job is to reproduce the fleet's dev node
  honestly, with the warning attached.**

## Versions note

Elasticsearch 8.19.13 per the fleet seed (Node-3 and Node-4, health
yellow single-node, xpack disabled). Config key spellings are the 8.x
surface; to confirm at validation: the fleet's exact `elasticsearch.yml`
and heap settings file-for-file.
