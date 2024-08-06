#!/bin/bash

# Set the storage pool name
STORAGE_POOL="default"

# List all containers
containers=$(lxc list --format csv -c n)

# Iterate over each container
for container in $containers; do
  echo "Container: $container"
  
  # Show storage volume details
  volume_info=$(lxc storage volume show $STORAGE_POOL container/$container)
  
  # Extract and print the size information
  size=$(echo "$volume_info" | grep "size:" | awk '{print $2}')
  echo "Size: $size"
  echo "-----------------------"
done

