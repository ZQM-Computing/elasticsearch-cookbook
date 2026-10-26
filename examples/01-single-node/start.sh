#!/usr/bin/env bash
# Start the single-node dev instance and wait for the health check.
# Design-only: assumes an Elasticsearch 8.19.13 distribution extracted
# locally with ./config/elasticsearch.yml and ./config/jvm.options
# replaced by this pattern's files. Never run the dev (security-disabled)
# configuration on a public interface.
set -euo pipefail
: "${ES_HOME:?set ES_HOME to the extracted Elasticsearch directory}"
cp elasticsearch.yml "$ES_HOME/config/elasticsearch.yml"
cp jvm.options "$ES_HOME/config/jvm.options"
"$ES_HOME/bin/elasticsearch" -d -p /tmp/cookbook-es.pid
echo "Waiting for health (up to 120s)..."
for i in $(seq 1 60); do
  if curl -sS "http://localhost:9200/_cluster/health" 2>/dev/null | grep -q '"status"'; then
    break
  fi
  sleep 2
done
curl -sS "http://localhost:9200/_cluster/health"
echo
curl -sS "http://localhost:9200/_cat/nodes?v"
echo "Expected: status yellow (single node, no replicas) and exactly one node."
