#!/bin/bash

# This script sets up the React application server

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install required dependencies
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Node Exporter for Prometheus
EXPORTER_VERSION="1.6.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${EXPORTER_VERSION}/node_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${EXPORTER_VERSION}.linux-amd64*

# Create Node Exporter systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Create application directory
mkdir -p ~/app
cd ~/app

# Create docker-compose file
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  react-app:
    image: michaldevops/react-airbnb-clone:latest
    container_name: react-airbnb-clone
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - DATABASE_HOST=db-server
      - DATABASE_PORT=3306
      - DATABASE_NAME=reactapp
      - DATABASE_USER=reactuser
      - DATABASE_PASSWORD=reactpassword
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOF

# Create .env file for environment variables
cat > .env <<EOF
DATABASE_HOST=db-server
DATABASE_PORT=3306
DATABASE_NAME=reactapp
DATABASE_USER=reactuser
DATABASE_PASSWORD=reactpassword
EOF

echo "React application server setup complete!"
echo "The application will be deployed by Jenkins."
echo "Node Exporter is running on port 9100 for Prometheus monitoring."