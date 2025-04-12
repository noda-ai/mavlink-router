#!/bin/bash

# Submodule update required for Docker build
git submodule update --init --recursive

# Build and tag Docker image
docker build . -t noda-mavlink-router

# Check if arg $1 provided
if [ -z "$1" ]; then
  echo "Error: GCS IP not provided"
  echo "Please provide it as a command-line argument: $0 <ip_address>"
  exit 1
fi

echo "Setting up mavlink-router to start at boot with GCS IP $1..."

# Get the git project root directory
PROJECT_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
( crontab -l | grep -v -F "mavlink-router" ; echo "@reboot $PROJECT_ROOT/scripts/run-mavlink-router.sh $1 >> /tmp/cron_mavlink_router.log 2>&1" ) | crontab -

echo "Successfully configured cron job!"
