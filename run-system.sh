#!/usr/bin/env bash
set -euo pipefail

NETWORK=chinook-net
DB_CONTAINER=chinook-db
SEEDER_CONTAINER=chinook-seeder
GATEWAY_CONTAINER=chinook-gateway
AGENT_CONTAINER=chinook-agent

# Docker commands are added below, one commit per command
