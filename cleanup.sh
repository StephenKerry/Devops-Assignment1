#!/usr/bin/env bash
set -euo pipefail

# Cleanup commands are added below, mirroring run-system.sh

docker ps -aq --filter label=project=music-agent | xargs -r docker rm -f

docker image ls -q --filter label=project=music-agent | xargs -r docker rmi -f

docker network ls -q --filter label=project=music-agent | xargs -r docker network rm