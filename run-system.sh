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

docker volume create --label project=music-agent music-pgdata

docker run -d \
  --name "$DB_CONTAINER" \
  --network "$NETWORK" \
  --label project=music-agent \
  -v music-pgdata:/var/lib/postgresql \
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
    -v "$PWD/Chinook.db":/app/Chinook.db:ro \
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

  until docker logs "$GATEWAY_CONTAINER" 2>&1 | grep "Start sse server" > /dev/null; do
  echo "Waiting for MCP gateway..."
  sleep 2
done

  docker build --target agent --label project=music-agent -t "$AGENT_IMAGE" .

  docker run \
  --name "$AGENT_CONTAINER" \
  --network "$NETWORK" \
  --label project=music-agent \
  -v "$PWD/secret.ollama-api-key":/run/secrets/openai-api-key:ro \
  -e MCP_SERVER_URL="http://$GATEWAY_CONTAINER:8811/sse" \
  -e DATABASE_DIALECT=PostgreSQL \
  -e QUESTION="What are the top 3 albums by sales?" \
  -e OPENAI_API_BASE_URL=https://ollama.com/v1 \
  -e OPENAI_MODEL_NAME=gpt-oss:20b \
  "$AGENT_IMAGE"