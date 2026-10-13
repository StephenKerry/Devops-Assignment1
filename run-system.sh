#!/usr/bin/env bash
set -euo pipefail

NETWORK=music-net
DB_CONTAINER=music-db
SEEDER_CONTAINER=music-seeder
GATEWAY_CONTAINER=music-gateway
AGENT_CONTAINER=music-agent
SEEDER_IMAGE=music-seeder

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

  docker run \
  --name "$SEEDER_CONTAINER" \
  --network "$NETWORK" \
  --label project=music-agent \
  -v "$PWD/Chinook.db":/app/Chinook.db \
  -e SQLITE_FILE=/app/Chinook.db \
  -e DATABASE_URL="postgres://music_user:pass@music-db:5432/music" \
  "$SEEDER_IMAGE"