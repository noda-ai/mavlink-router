#!/bin/bash
# Script to run the mavlink-router Docker container with dynamic GCS_PORT based on MAV_SYS_ID

# Check if ground station IP was provided
if [ $# -ge 1 ]; then
  GCS_IP="$1"
  echo "Using GCS_IP=$GCS_IP from command-line argument"
else
  echo "Error: GCS_IP not provided"
  echo "Please provide it as a command-line argument: $0 <ip_address>"
  exit 1
fi

# Stop existing container if running
if [ -n "$(docker ps -q -f name=noda-mavlink-router)" ]; then
  docker stop noda-mavlink-router
fi

# Initial MAVLink port (for MAV_SYS_ID = 1)
BASE_PORT=14540

# Get MAV_SYS_ID from px4-param
MAV_SYS_ID=$(px4-param show MAV_SYS_ID 2>/dev/null | grep MAV_SYS_ID | awk -F': ' '{print $2}' || echo "1")

# Get localhost MAVSDK UDP port from voxl-vision-hub.conf
CONFIG_FILE="/etc/modalai/voxl-vision-hub.conf"
DEFAULT_PORT=14551

if [ -f "$CONFIG_FILE" ]; then
  # Look for the line with "localhost_udp_port_number" that's not commented out
  PORT_LINE=$(grep -v '^[[:space:]]*#' "$CONFIG_FILE" | grep "localhost_udp_port_number" | tail -1)
  LOCAL_MAVLINK_ENABLED_LINE=$(grep -v '^[[:space:]]*#' "$CONFIG_FILE" | grep "en_localhost_mavlink_udp" | tail -1)

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

  # Check if local mavlink is enabled
  if [ -n "$LOCAL_MAVLINK_ENABLED_LINE" ]; then
    # Get boolean value
    LOCAL_MAVLINK_ENABLED=$(echo "$LOCAL_MAVLINK_ENABLED_LINE" | grep -o 'true\|false' | head -1)

    # Validate that we got a boolean
    if [[ "$LOCAL_MAVLINK_ENABLED" == "true" ]]; then
      echo "Local mavlink is enabled in $CONFIG_FILE"
    else
      # Enable it
      echo "Enabling local mavlink in $CONFIG_FILE"
      # Use a flexible sed pattern for JSON format with variable whitespace
      sed -i 's/"en_localhost_mavlink_udp"[[:space:]]*:[[:space:]]*false/"en_localhost_mavlink_udp": true/g' "$CONFIG_FILE"
    fi
  fi
else
  VOXL_VISION_HUB_PORT=$DEFAULT_PORT
  echo "Config file $CONFIG_FILE not found, using default port: $VOXL_VISION_HUB_PORT"
fi

# Calculate GCS_PORT
GCS_PORT=$((BASE_PORT + MAV_SYS_ID - 1))
echo "Using GCS_IP=$GCS_IP, MAV_SYS_ID=$MAV_SYS_ID, GCS_PORT=$GCS_PORT"

# Ensure VOXL services are running
echo "Ensure voxl-mavlink-server is running"
systemctl restart voxl-mavlink-server
systemctl status --no-pager voxl-mavlink-server

systemctl restart voxl-vision-hub
systemctl status --no-pager voxl-vision-hub

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
