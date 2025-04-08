#!/bin/bash
# Script to run the mavlink-router Docker container with dynamic GCS_PORT based on MAV_SYS_ID

# Check if command-line argument was provided first
if [ $# -ge 1 ]; then
  GCS_IP="$1"
  echo "Using GCS_IP=$GCS_IP from command-line argument"
# If not, check if environment variable is set
elif [ -n "$GCS_IP" ]; then
  echo "Using GCS_IP=$GCS_IP from environment variable"
# If neither, show error and exit
else
  echo "Error: GCS_IP not provided"
  echo "Please provide it as a command-line argument: $0 <ip_address>"
  echo "Or set it as an environment variable: export GCS_IP=<ip_address>"
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
