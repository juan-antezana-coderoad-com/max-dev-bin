#!/bin/bash -e

echo
echo "### creating network"
echo

MAX_NETWORK=${MAX_NETWORK:='max-network'}
MAX_SUBNET=${MAX_SUBNET:='172.18.0.0/23'}
echo "MAX_NETWORK: $MAX_NETWORK"
echo "MAX_SUBNET: $MAX_SUBNET"
echo

# delete network if exists
if ! [[ -z `docker network ls | grep $MAX_NETWORK` ]]; then
  docker network rm $MAX_NETWORK
fi

# create network
docker network create -d bridge --subnet=$MAX_SUBNET $MAX_NETWORK
