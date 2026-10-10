#!/usr/bin/env bash
set -euo pipefail

# Cleanup commands are added below, mirroring run-system.sh

docker network ls -q --filter label=project=music-agent | xargs -r docker network rm