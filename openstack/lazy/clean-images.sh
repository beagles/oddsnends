#!/bin/bash
echo "Removing container images!"
docker images | awk -e '{print $1 ":" $2; }' | while read; do docker rmi $REPLY; done
