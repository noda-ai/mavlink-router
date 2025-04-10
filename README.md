# MAVLink Router

This repository is a customized fork of [mavlink-router](https://github.com/mavlink-router/mavlink-router)
that is designed for deployment on VOXL UAVs to redirect its onboard mavsdk to
a unique port on the ground station.

## One-Time Setup

**ETC**: ~2 minutes per VOXL

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

# Update submodules required for Docker build
git submodule update --init --recursive

# Build and tag image
docker build . -t noda-mavlink-router
```

## Run Automatically on Boot

SSH into the VOXL, then run the following:

```sh
# Set GCS_IP environment variable on every boot
mkdir -p ~/.profile.d
echo "export GCS_IP=10.8.0.2" > ~/.profile.d/noda.sh
chmod +x ~/.profile.d/noda.sh
```

Then edit the VOXL's crontab:

```sh
crontab -e
```

Add the following line:

```sh
@reboot /home/root/mavlink-router/run-mavlink-router.sh
```

Now the VOXL should start up the `mavlink-router` container on every boot pointed to the ground station at `10.8.0.2`.

## Run Manually

SSH into the VOXL, then run the following:

```sh
# Start mavlink-router
# - uses $1 or $GCS_IP for target (ground station) IP address
# - automatically sets port based on MAV_SYS_ID (check with `px4-param show MAV_SYS_ID`)
./run-mavlink-router.sh <ground_station_ip>
```
