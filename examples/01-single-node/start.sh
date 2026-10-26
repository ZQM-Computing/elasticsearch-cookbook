#!/usr/bin/env bash
# Start the single-node dev instance and verify it becomes healthy.
# Use only with a dedicated Elasticsearch 8.19.13 development distribution.
set -euo pipefail
: "${ES_HOME:?set ES_HOME to the extracted Elasticsearch directory}"
[[ -x "$ES_HOME/bin/elasticsearch" ]] || { echo "Elasticsearch executable missing under ES_HOME: $ES_HOME" >&2; exit 2; }
[[ -d "$ES_HOME/config" ]] || { echo "Elasticsearch config directory missing: $ES_HOME/config" >&2; exit 2; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$DIR/elasticsearch.yml" "$ES_HOME/config/elasticsearch.yml"
cp "$DIR/jvm.options" "$ES_HOME/config/jvm.options"
"$ES_HOME/bin/elasticsearch" -d -p /tmp/cookbook-es.pid

echo "Waiting for health (up to 120s)..."
ready=0
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error --max-time 2 "http://127.0.0.1:9200/_cluster/health" -o /tmp/cookbook-es-health.json 2>/dev/null; then
    ready=1
    break
  fi
  sleep 2
done
if [[ "$ready" != 1 ]]; then
  echo "Elasticsearch did not become ready within 120 seconds." >&2
  echo "Inspect logs under $ES_HOME/logs before retrying." >&2
  exit 1
fi

health="$(cat /tmp/cookbook-es-health.json)"
printf '%s\n' "$health"
grep -Eq '"status"[[:space:]]*:[[:space:]]*"yellow"' <<<"$health" || {
  echo "Expected yellow health for this single-node configuration." >&2
  exit 1
}
nodes="$(curl --fail --silent --show-error "http://127.0.0.1:9200/_cat/nodes?h=name")"
node_count="$(grep -cve '^[[:space:]]*$' <<<"$nodes" || true)"
if [[ "$node_count" != 1 ]]; then
  printf 'Expected exactly one node; found %s:\n%s\n' "$node_count" "$nodes" >&2
  exit 1
fi
grep -Fxq 'cookbook-node-1' <<<"$nodes" || {
  printf 'Expected node cookbook-node-1, got:\n%s\n' "$nodes" >&2
  exit 1
}
echo "PASS: one node (cookbook-node-1), health yellow."
