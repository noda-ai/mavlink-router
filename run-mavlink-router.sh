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

# Get localhost MAVSDK UDP port from voxl-vision-hub.conf
CONFIG_FILE="/etc/modalai/voxl-vision-hub.conf"
DEFAULT_PORT=14551

if [ -f "$CONFIG_FILE" ]; then
  # Use a more specific pattern to find the correct entry
  # Look for the line with "localhost_udp_port_number" that's not commented out
  PORT_LINE=$(grep -v '^[[:space:]]*#' "$CONFIG_FILE" | grep "localhost_udp_port_number" | tail -1)

  if [ -n "$PORT_LINE" ]; then
    # Extract just the number after the colon and before the comma or end of line
    VOXL_VISION_HUB_PORT=$(echo "$PORT_LINE" | grep -o '[0-9]\+' | head -1)

    # Validate that we got a number
    if [[ "$VOXL_VISION_HUB_PORT" =~ ^[0-9]+$ ]]; then
      echo "Found localhost UDP port: $VOXL_VISION_HUB_PORT from $CONFIG_FILE"
    else
      VOXL_VISION_HUB_PORT=$DEFAULT_PORT
      echo "Failed to extract valid port number, using default: $VOXL_VISION_HUB_PORT"
    fi
  else
    VOXL_VISION_HUB_PORT=$DEFAULT_PORT
    echo "No 'localhost_udp_port_number' entry found in $CONFIG_FILE, using default: $VOXL_VISION_HUB_PORT"
  fi
else
  VOXL_VISION_HUB_PORT=$DEFAULT_PORT
  echo "Config file $CONFIG_FILE not found, using default port: $VOXL_VISION_HUB_PORT"
fi

# Calculate GCS_PORT
GCS_PORT=$((BASE_PORT + MAV_SYS_ID))
echo "Using GCS_IP=$GCS_IP, MAV_SYS_ID=$MAV_SYS_ID, GCS_PORT=$GCS_PORT"

# Ensure
echo "Ensure voxl-mavlink-server is running"
systemctl restart voxl-mavlink-server
systemctl status voxl-mavlink-server

# Run the container with explicit command
echo "Starting mavlink-router container using the following configurations:"
echo ""
echo "  Ground station: $GCS_IP:$GCS_PORT"
echo "  Onboard port: $VOXL_VISION_HUB_PORT"
echo ""

docker run --rm -d \
  --network=host \
  --name=noda-mavlink-router \
  noda-mavlink-router \
  /mavlink-router/build/src/mavlink-routerd -e "$GCS_IP:$GCS_PORT" 0.0.0.0:$VOXL_VISION_HUB_PORT
