#!/bin/bash

docker compose -f compose.yocto.yaml up -d
CONTAINER_NAME=$(docker compose -f compose.yocto.yaml ps -q yocto)
docker exec -it $CONTAINER_NAME /bin/zsh
docker compose -f compose.yocto.yaml down
