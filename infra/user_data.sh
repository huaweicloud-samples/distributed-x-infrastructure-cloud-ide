#!/bin/bash
# code-server user data script for Huawei Cloud ECS
# Version: v4 - OBS internal-network download + root-run systemd service
# Fixed: GitHub download timeout (use OBS internal CDN), 217/USER service error

echo "INFO: Starting UserData script execution"

# Inject SSH public key if provided
if [ -n "${PUBLIC_KEY}" ]; then
  echo "INFO: Injecting SSH public key for ubuntu user"
  id ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu
  mkdir -p /home/ubuntu/.ssh
  echo "${PUBLIC_KEY}" >> /home/ubuntu/.ssh/authorized_keys
  chmod 700 /home/ubuntu/.ssh
  chmod 600 /home/ubuntu/.ssh/authorized_keys
  chown -R ubuntu:ubuntu /home/ubuntu/.ssh
  echo "INFO: SSH public key injected"
fi

# Install prerequisites
echo "INFO: Updating apt and installing prerequisites"
apt-get -o DPkg::Lock::Timeout=-1 update
DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=-1 install -y curl unzip

# Download code-server from Huawei Cloud OBS (internal network, fast & reliable)
# Uploaded once via obs_upload.py, public-read ACL
echo "INFO: Installing code-server v${version}"
DEB_FILE="/tmp/code-server_${version}_amd64.deb"
OBS_URL="https://code-server-deploy-temp.obs.cn-north-4.myhuaweicloud.com/code-server_${version}_amd64.deb"

echo "INFO: Downloading from OBS: $$OBS_URL"
curl -fL --connect-timeout 15 --max-time 300 -o "$$DEB_FILE" "$$OBS_URL"

if [ ! -s "$$DEB_FILE" ]; then
  echo "ERROR: OBS download failed"
  exit 1
fi

echo "INFO: Installing code-server package"
dpkg -i "$$DEB_FILE"
apt-get -f install -y
rm -f "$$DEB_FILE"

# Ensure ubuntu user exists (some Huawei Cloud Ubuntu images omit it)
id ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu

# Create a custom systemd service running as root with bind-addr 0.0.0.0:8080
# Avoids the 217/USER error from template service code-server@ubuntu
echo "INFO: Writing systemd service (root, 0.0.0.0:8080)"
cat > /etc/systemd/system/code-server.service << 'EOF'
[Unit]
Description=code-server
After=network.target

[Service]
Type=simple
Environment=HOME=/root
ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "INFO: Enabling and starting code-server"
systemctl daemon-reload
systemctl enable --now code-server.service

# Wait for code-server to start (up to 60 seconds)
echo "INFO: Waiting for code-server to start..."
_WAIT_COUNT=0
while [ $$_WAIT_COUNT -lt 12 ]; do
  sleep 5
  _WAIT_COUNT=$((_WAIT_COUNT + 1))
  if systemctl is-active --quiet code-server.service; then
    echo "INFO: code-server running after $$_WAIT_COUNT x5 seconds"
    break
  fi
done

if [ $$_WAIT_COUNT -ge 12 ]; then
  echo "ERROR: code-server failed to start after 60 seconds"
  journalctl -u code-server.service --no-pager -n 20
fi

# Install Huawei Cloud Toolkit extension
echo "INFO: Installing Huawei Cloud Toolkit extension"
code-server --install-extension huawei-cloud.huawei-cloud-toolkit || true

# Final restart
echo "INFO: Final restart of code-server"
systemctl restart code-server.service
sleep 5

# Show password for verification
echo "INFO: code-server password (for verification):"
grep "^password:" /root/.config/code-server/config.yaml || echo "WARN: password not found"

echo "INFO: UserData script execution finished"
