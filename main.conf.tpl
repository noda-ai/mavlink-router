[General]
ReportStats=false
MavlinkDialect=auto
DebugLogLevel=info

# Redirect onboard mavsdk connection (0.0.0.0:14551, configured in
# /etc/modalai/voxl-vision-hub.conf) to GCS IP on unique port determined by
# MAV_SYS_ID of this UXV
[UdpEndpoint onboard]
Mode=Server
Address=0.0.0.0
Port=14551

[UdpEndpoint urza]
Mode=Normal
Address={GCS_IP}
Port={GCS_PORT}
