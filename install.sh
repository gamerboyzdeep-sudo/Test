#!/bin/bash
set -e

echo "[1/7] Checking storage..."
df -h

echo "[2/7] Creating Docker data directory..."
sudo mkdir -p /tmp/docker-data

echo "[3/7] Configuring Docker daemon..."
sudo bash -c 'cat <<EOF > /etc/docker/daemon.json
{
  "data-root": "/tmp/docker-data"
}
EOF'

echo "[4/7] Restarting Docker..."
sudo systemctl restart docker || echo "Restart manually if needed"

echo "[5/7] Creating docker-compose file (windows10.yml)..."
cat <<EOF > windows10.yml
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "10"
      USERNAME: \${WINDOWS_USERNAME}
      PASSWORD: \${WINDOWS_PASSWORD}
      RAM_SIZE: "4G"
      CPU_CORES: "4"
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
    volumes:
      - /tmp/docker-data:/mnt/disco1
      - windows-data:/mnt/windows-data
    devices:
      - "/dev/kvm:/dev/kvm"
      - "/dev/net/tun:/dev/net/tun"
    stop_grace_period: 2m
    restart: always

volumes:
  windows-data:
EOF

echo "[6/7] Creating .env file..."
read -p "Enter Windows username: " winuser
read -sp "Enter Windows password: " winpass
echo
echo "WINDOWS_USERNAME=$winuser" > .env
echo "WINDOWS_PASSWORD=$winpass" >> .env

echo "[7/7] Starting container..."
docker-compose -f windows10.yml up -d

echo "✅ Setup complete. Use port 3389 to connect via RDP."
