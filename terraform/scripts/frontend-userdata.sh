#!/bin/bash
# ─── Frontend EC2 User Data Script ────────────────────────────────────────
# Ubuntu 22.04 LTS compatible bootstrap.
# Installs Docker, pulls and runs the frontend container on ASG instances.
# Executed at EC2 boot by the launch template.

set -euo pipefail

# Template variables injected by Terraform templatefile()
PROJECT_NAME="${project_name}"
INTERNAL_ALB_DNS="${internal_alb_dns}"
AWS_REGION="${aws_region}"
FRONTEND_ECR_URL="${frontend_ecr_url}"
IMAGE_TAG="${docker_image_tag}"

LOG_FILE="/var/log/shopmesh-userdata.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== ShopMesh Frontend Bootstrap START $(date) ==="

# ─── 1. Update system ─────────────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
#apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# ─── 2. Install dependencies ──────────────────────────────────────────────
apt-get install -y \
  docker.io \
  docker-compose-v2 \
  curl \
  unzip \
  jq \
  awscli

# ─── 3. Enable and start Docker ───────────────────────────────────────────
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# ─── 4. Install CloudWatch Agent (Ubuntu .deb) ────────────────────────────
CW_AGENT_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
curl -fsSL "$CW_AGENT_URL" -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb
rm -f /tmp/amazon-cloudwatch-agent.deb

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/shopmesh-userdata.log",
            "log_group_name": "/shopmesh/frontend",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "ShopMesh/Frontend",
    "metrics_collected": {
      "cpu": { "measurement": ["cpu_usage_active"] },
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["disk_used_percent"] }
    }
  }
}
EOF
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# ─── 5. Authenticate to ECR and resolve image ─────────────────────────────
# Extract ECR registry hostname from the repository URL
ECR_REGISTRY="$(echo "$FRONTEND_ECR_URL" | cut -d'/' -f1)"

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

FRONTEND_IMAGE="$FRONTEND_ECR_URL:$IMAGE_TAG"

# ─── 6. Create app directory ──────────────────────────────────────────────
mkdir -p /opt/shopmesh/frontend

# ─── 7. Write docker-compose.yml ──────────────────────────────────────────
cat > /opt/shopmesh/frontend/docker-compose.yml <<EOF
services:
  frontend:
    image: $FRONTEND_IMAGE
    container_name: shopmesh-frontend
    restart: always
    ports:
      - "80:80"
    environment:
      - INTERNAL_ALB_URL=http://$INTERNAL_ALB_DNS
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
EOF

# ─── 8. Pull image explicitly then start frontend container ──────────────
cd /opt/shopmesh/frontend
docker pull "$FRONTEND_IMAGE"
docker compose up -d

# ─── 9. Configure auto-restart on reboot ──────────────────────────────────
cat > /etc/systemd/system/shopmesh-frontend.service <<EOF
[Unit]
Description=ShopMesh Frontend
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/shopmesh/frontend
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable shopmesh-frontend

echo "=== ShopMesh Frontend Bootstrap DONE $(date) ==="
