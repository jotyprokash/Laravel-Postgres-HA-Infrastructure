#!/bin/bash
# 04_app_deployment.sh
# Run this on VM-1 (Application Server)
set -e

echo "Provisioning Application Server (VM-1)..."

# 1. Install Docker
apt-get update -y
apt-get install -y ca-certificates curl gnupg pgbouncer
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 2. Kernel Tuning
cat <<EOF > /etc/sysctl.d/99-app.conf
net.core.somaxconn = 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
EOF
sysctl -p /etc/sysctl.d/99-app.conf

# 3. Configure PgBouncer
cp config/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
HASH=$(echo -n "laravel_passlaravel_db" | md5sum | awk '{print $1}')
echo "\"laravel_db\" \"md5${HASH}\"" > /etc/pgbouncer/userlist.txt
systemctl restart pgbouncer
systemctl enable pgbouncer

# 4. Build and start the Laravel container
cd /opt/tenbyte-devops-assessment
docker compose -f docker/docker-compose.yml up -d --build

echo "Application deployed. Access at http://163.61.156.56"
