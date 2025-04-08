#!/bin/bash
# Script to run the mavlink-router Docker container with dynamic GCS_PORT based on MAV_SYS_ID

# Check if GCS_IP is set
if [ -z "$GCS_IP" ]; then
  echo "Error: GCS_IP environment variable is not set"
  echo "Please set it before running this script: export GCS_IP=<ip_address>"
  exit 1
fi

# Default values
BASE_PORT=14540

# Get MAV_SYS_ID from px4-param
MAV_SYS_ID=$(px4-param show MAV_SYS_ID 2>/dev/null | grep MAV_SYS_ID | awk -F': ' '{print $2}' || echo "1")

# Calculate GCS_PORT
GCS_PORT=$((BASE_PORT + MAV_SYS_ID))
echo "Using GCS_IP=$GCS_IP, MAV_SYS_ID=$MAV_SYS_ID, GCS_PORT=$GCS_PORT"

# Run the container
docker run --rm -it \
  --network=host \
  -e GCS_IP="$GCS_IP" \
  -e GCS_PORT="$GCS_PORT" \
  noda-mavlink-router
