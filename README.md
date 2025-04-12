# MAVLink Router

This repository is a customized fork of [mavlink-router](https://github.com/mavlink-router/mavlink-router)
that is designed for deployment on VOXL UAVs to redirect its onboard mavsdk to
a unique port on the ground station.

Ensure the Docker is installed on the VOXL before installing `mavlink-router`.

## One-Time Setup

**ETC**: ~3 minutes per VOXL

### On Laptop

From any laptop on the same network as the VOXL, run the following:

```sh
# Clone repo
git clone git@github.com:noda-ai/mavlink-router.git

# (optionally check out specific tag)

# Copy whole directory to VOXL (e.g. 10.8.0.7)
sshpass -e scp -r ./mavlink-router root@10.8.0.7:/home/root/
```

Repeat the last command for each VOXL you want to deploy.

### On VOXL

SSH into the VOXL, then run the following:

```sh
# Navigate to mavlink-router
cd ~/mavlink-router

# Set up mavlink-router and configure auto-start (via cron) with a preset ground station IP (e.g. 10.8.0.2)
./scripts/setup.sh 10.8.0.2
```

## Run Manually

SSH into the VOXL, then run the following:

```sh
# Start mavlink-router
# - takes in one argument: ground station IP address
# - automatically sets port based on MAV_SYS_ID (check with `px4-param show MAV_SYS_ID`)
./scripts/run-mavlink-router.sh 10.8.0.2
```

This will stop any running `mavlink-router` container and start a new one.
