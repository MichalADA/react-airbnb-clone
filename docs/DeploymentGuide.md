# Deployment Guide: React App CI/CD Pipeline

This guide provides step-by-step instructions for setting up a complete CI/CD pipeline for a React application using Jenkins, Docker, AWS, and monitoring tools.

## Architecture Overview

The architecture consists of:
- **Ansible Control Node**: Used to configure and manage all other nodes
- **Jenkins Server**: CI/CD pipeline execution
- **Database Server**: MySQL database for the application
- **Monitoring Server**: Prometheus and Grafana for monitoring
- **Application Server**: For running the React application in Docker containers

## Phase 1: Infrastructure Setup

### Step 1: Launch Ansible Control Node

1. Launch an EC2 instance with Ubuntu 22.04
2. Connect via SSH and update the system:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
3. Clone the repository:
   ```bash
   git clone https://github.com/Michal-Devops/Airbnb-Clone-Jenkins.git
   cd Airbnb-Clone-Jenkins
   ```
4. Install Ansible by running the provided script:
   ```bash
   chmod +x ansible.sh
   ./ansible.sh
   ```
5. Prepare your SSH key:
   ```bash
   mkdir -p keys
   cp /path/to/your/aws-key.pem keys/
   chmod 600 keys/aws-key.pem
   ```
6. Update the `inventory.yml` file with the actual IPs of your servers

### Step 2: Configure Jenkins Server

1. From the Ansible control node, run:
   ```bash
   ansible-playbook -i inventory.yml jenkins.yml
   ```
2. This will install:
   - Jenkins
   - Docker
   - SonarQube Scanner
   - Node.js
   - Trivy
   - Required packages

3. After installation, retrieve the Jenkins admin password:
   ```bash
   ssh -i keys/aws-key.pem ubuntu@jenkins-server-ip "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
   ```

4. Access the Jenkins web interface at `http://jenkins-server-ip:8080`
5. Complete the initial setup and install suggested plugins

### Step 3: Configure Monitoring Server

1. From the Ansible control node, run:
   ```bash
   ansible-playbook -i inventory.yml monitoring.yml
   ```
2. This will install:
   - Prometheus
   - Node Exporter
   - Grafana
   - SmokePing

3. Access Grafana at `http://monitoring-server-ip:3000` (default credentials: admin/admin)
4. Install and configure dashboards:
   ```bash
   scp -i keys/aws-key.pem grafana-dashboard-setup.sh ubuntu@monitoring-server-ip:~/
   ssh -i keys/aws-key.pem ubuntu@monitoring-server-ip "chmod +x grafana-dashboard-setup.sh && ./grafana-dashboard-setup.sh"
   ```

### Step 4: Configure Database Server

1. From the Ansible control node, run:
   ```bash
   ansible-playbook -i inventory.yml database.yml
   ```
2. This will install and configure:
   - MySQL Server
   - Node Exporter for monitoring
   - Create the database and user for the application

## Phase 2: Jenkins Pipeline Configuration

### Step 1: Configure Jenkins Plugins

1. Go to "Manage Jenkins" → "Plugins" → "Available Plugins"
2. Install the following plugins:
   - Eclipse Temurin Installer
   - SonarQube Scanner
   - NodeJS Plugin
   - Docker Pipeline
   - Docker Commons
   - Docker API
   - docker-build-step
   - Prometheus metrics
   - OWASP Dependency-Check

### Step 2: Configure Jenkins Tools

1. Go to "Manage Jenkins" → "Tools"
2. Add JDK installation:
   - Name: JDK17
   - Install automatically: Yes
   - Select "Eclipse Temurin installer"
   - Version: 17 (LTS)

3. Add NodeJS installation:
   - Name: NodeJS
   - Install automatically: Yes
   - Version: NodeJS 16.x

### Step 3: Add Docker Hub Credentials

1. Go to "Manage Jenkins" → "Credentials" → "System" → "Global credentials"
2. Click "Add Credentials"
3. Select "Username with password"
4. Enter your Docker Hub username and password
5. Set ID as "docker"
6. Click "OK"

### Step 4: Create Jenkins Pipeline

1. Go to Jenkins dashboard
2. Click "New Item"
3. Enter a name for your pipeline (e.g., "react-airbnb-clone")
4. Select "Pipeline" and click "OK"
5. In the pipeline configuration:
   - Under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" as SCM
   - Enter your repository URL
   - Specify the branch (e.g., "*/main")
   - Set "Script Path" to "Jenkinsfile"
   - Click "Save"

### Step 5: Add Jenkins to Docker Group

1. SSH into the Jenkins server:
   ```bash
   ssh -i keys/aws-key.pem ubuntu@jenkins-server-ip
   ```
2. Add the Jenkins user to the Docker group:
   ```bash
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

## Phase 3: Monitoring Configuration

### Step 1: Update Prometheus Configuration

1. SSH into the monitoring server:
   ```bash
   ssh -i keys/aws-key.pem ubuntu@monitoring-server-ip
   ```
2. Copy the Prometheus configuration:
   ```bash
   sudo cp ~/prometheus.yml /etc/prometheus/prometheus.yml
   ```
3. Validate and reload the configuration:
   ```bash
   promtool check config /etc/prometheus/prometheus.yml
   curl -X POST http://localhost:9090/-/reload
   ```

### Step 2: Configure Jenkins Prometheus Metrics

1. In Jenkins, go to "Manage Jenkins" → "Plugins" → "Available"
2. Search for and install "Prometheus metrics"
3. Restart Jenkins if necessary
4. Metrics will be available at `http://jenkins-server-ip:8080/prometheus`

### Step 3: Set Up Grafana Dashboards

1. Access Grafana at `http://monitoring-server-ip:3000`
2. Import the following dashboards:
   - Node Exporter (ID: 1860)
   - Jenkins (ID: 9964)
   - MySQL (ID: 7362)
   - Docker (ID: 893)

## Phase 4: Application Deployment

### Step 1: Set Up Application Server

1. SSH into the application server:
   ```bash
   ssh -i keys/aws-key.pem ubuntu@app-server-ip
   ```
2. Run the application setup script:
   ```bash
   curl -s https://raw.githubusercontent.com/Michal-Devops/Airbnb-Clone-Jenkins/main/app-setup.sh | bash
   ```

### Step 2: Trigger Jenkins Pipeline

1. Go to your Jenkins pipeline
2. Click "Build Now" to start the pipeline
3. The pipeline will:
   - Check out the source code
   - Install dependencies
   - Run tests
   - Perform SonarQube analysis
   - Scan for security vulnerabilities with Trivy
   - Build a Docker image
   - Push the image to Docker Hub
   - Deploy the application to the application server

### Step 3: Verify Deployment

1. Access your application at `http://app-server-ip`
2. Check the monitoring dashboards in Grafana to ensure everything is working correctly

## Troubleshooting

### Jenkins Pipeline Issues

- Check Jenkins logs: `sudo journalctl -u jenkins`
- Ensure Docker has correct permissions: `sudo ls -l /var/run/docker.sock`
- Verify Jenkins can access the Docker daemon: `sudo -u jenkins docker ps`

### Monitoring Issues

- Check Prometheus targets: `http://monitoring-server-ip:9090/targets`
- Verify Node Exporter is running: `curl http://localhost:9100/metrics`
- Check Prometheus logs: `sudo journalctl -u prometheus`
- Check Grafana logs: `sudo journalctl -u grafana-server`

### Database Issues

- Check MySQL status: `systemctl status mysql`
- Verify database connection: `mysql -u reactuser -p -h db-server-ip reactapp`
- Check MySQL logs: `sudo journalctl -u mysql`

## Maintenance

### Backup

1. Database backup:
   ```bash
   mysqldump -u root -p --all-databases > backup.sql
   ```

2. Configuration backup:
   ```bash
   tar -czvf config-backup.tar.gz /etc/prometheus /etc/grafana
   ```

### Updates

1. Update Jenkins plugins through the web interface
2. Update system packages:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
3. Update Docker images:
   ```bash
   docker pull michaldevops/react-airbnb-clone:latest
   ```

## Security Considerations

- Ensure all servers have proper security groups/firewall rules
- Use strong passwords for all services
- Regularly update all components
- Monitor security vulnerabilities with Trivy
- Use HTTPS for all web interfaces in production