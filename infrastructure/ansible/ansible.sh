#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Python and pip if not already installed
sudo apt install -y python3 python3-pip

# Install Ansible
sudo apt install -y ansible

# Install additional dependencies
sudo apt install -y sshpass
sudo pip3 install boto3 botocore

# Verify installation
ansible --version

# Create Ansible configuration directory if it doesn't exist
mkdir -p ~/.ansible
touch ~/.ansible/ansible.cfg

# Configure Ansible defaults
cat > ~/.ansible/ansible.cfg << EOL
[defaults]
host_key_checking = False
inventory = ./inventory.yml
private_key_file = ./keys/aws-key.pem
remote_user = ubuntu
EOL

echo "Ansible installation and configuration completed."