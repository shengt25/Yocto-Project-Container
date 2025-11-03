#!/bin/bash

docker compose -f compose.yocto-only.yaml up -d
CONTAINER_NAME=$(docker compose -f compose.yocto-only.yaml ps -q yocto)
docker exec -it $CONTAINER_NAME /bin/zsh
docker compose -f compose.yocto-only.yaml down
