#!/usr/bin/env bash
set -euo pipefail


docker ps -aq --filter label=project=music-agent | xargs -r docker rm -f -v


docker volume ls -q --filter label=project=music-agent | xargs -r docker volume rm


docker network ls -q --filter label=project=music-agent | xargs -r docker network rm


docker image ls -q --filter label=project=music-agent | xargs -r docker rmi -f