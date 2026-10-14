#!/usr/bin/env bash
set -euo pipefail

NETWORK=music-net
DB_CONTAINER=music-db
SEEDER_CONTAINER=music-seeder
GATEWAY_CONTAINER=music-gateway
AGENT_CONTAINER=music-agent
SEEDER_IMAGE=music-seeder
AGENT_IMAGE=music-agent-image

# Docker commands are added below, one commit per command
docker network create --label project=music-agent "$NETWORK"

docker run -d \
  --name "$DB_CONTAINER" \
  --network "$NETWORK" \
  --label project=music-agent \
  -e POSTGRES_USER=music_user \
  -e POSTGRES_PASSWORD=pass \
  -e POSTGRES_DB=music \
  postgres

  docker build --target seeder --label project=music-agent -t "$SEEDER_IMAGE" .

  until docker exec "$DB_CONTAINER" pg_isready -h localhost -U music_user -d music -q; do
  echo "Waiting for Postgres..."
  sleep 1
done

  docker run \
  --name "$SEEDER_CONTAINER" \
  --network "$NETWORK" \
  --label project=music-agent \
  -v "$PWD/Chinook.db":/app/Chinook.db \
  -e SQLITE_FILE=/app/Chinook.db \
  -e DATABASE_URL="postgres://music_user:pass@music-db:5432/music" \
  "$SEEDER_IMAGE"

  docker run -d \
  --name "$GATEWAY_CONTAINER" \
  --network "$NETWORK" \
  --label project=music-agent \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/mcp_config.yaml":/mcp_config.yaml:ro \
  -v "$PWD/mcp_secret.env":/run/secrets/database-url:ro \
  docker/mcp-gateway:latest \
  --transport=sse \
  --secrets=/run/secrets/database-url \
  --allow-unauthenticated \
  --servers=cockroachdb \
  --tools=execute_query \
  --config=/mcp_config.yaml

  docker build --target agent --label project=music-agent -t "$AGENT_IMAGE" .