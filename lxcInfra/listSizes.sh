#!/bin/bash

# Path to the LXD storage pool
STORAGE_PATH="/var/snap/lxd/common/lxd/storage-pools/default/containers/"

# Check if the storage path exists
if [ ! -d "$STORAGE_PATH" ]; then
  echo "Storage path $STORAGE_PATH does not exist."
  exit 1
fi

# List all containers
containers=$(lxc list --format csv -c n)

# Iterate over each container and get the disk usage
for container in $containers; do
  container_path="${STORAGE_PATH}${container}"

  if [ -d "$container_path" ]; then
    size=$(sudo du -sh "$container_path" | awk '{print $1}')
    echo "Container: $container"
    echo "Size: $size"
    echo "-----------------------"
  else
    echo "Container path $container_path does not exist."
  fi
done

