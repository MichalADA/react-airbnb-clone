#!/bin/bash

# This script sets up Grafana dashboards for monitoring
# Run this after Grafana is installed and running

# Define variables
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin"
PROMETHEUS_URL="http://localhost:9090"

# Function to wait for Grafana to be ready
wait_for_grafana() {
  echo "Waiting for Grafana to be ready..."
  while ! curl -s "$GRAFANA_URL/api/health" > /dev/null; do
    sleep 5
  done
  echo "Grafana is ready!"
}

# Add Prometheus data source
add_prometheus_datasource() {
  echo "Adding Prometheus data source..."
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/datasources" \
    -d '{
      "name": "Prometheus",
      "type": "prometheus",
      "url": "'"$PROMETHEUS_URL"'",
      "access": "proxy",
      "isDefault": true
    }'
  echo -e "\nPrometheus data source added!"
}

# Import Node Exporter dashboard
import_node_exporter_dashboard() {
  echo "Importing Node Exporter dashboard..."
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/dashboards/import" \
    -d '{
      "dashboard": {"id": null, "uid": null, "title": "Node Exporter Dashboard", "tags": ["node", "prometheus"], "timezone": "browser", "schemaVersion": 16, "version": 0},
      "folderId": 0,
      "overwrite": true,
      "inputs": [{"name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus"}],
      "path": "https://grafana.com/api/dashboards/1860/revisions/27/download"
    }'
  echo -e "\nNode Exporter dashboard imported!"
}

# Import Jenkins dashboard
import_jenkins_dashboard() {
  echo "Importing Jenkins dashboard..."
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/dashboards/import" \
    -d '{
      "dashboard": {"id": null, "uid": null, "title": "Jenkins Dashboard", "tags": ["jenkins", "prometheus"], "timezone": "browser", "schemaVersion": 16, "version": 0},
      "folderId": 0,
      "overwrite": true,
      "inputs": [{"name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus"}],
      "path": "https://grafana.com/api/dashboards/9964/revisions/1/download"
    }'
  echo -e "\nJenkins dashboard imported!"
}

# Import MySQL dashboard
import_mysql_dashboard() {
  echo "Importing MySQL dashboard..."
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/dashboards/import" \
    -d '{
      "dashboard": {"id": null, "uid": null, "title": "MySQL Dashboard", "tags": ["mysql", "prometheus"], "timezone": "browser", "schemaVersion": 16, "version": 0},
      "folderId": 0,
      "overwrite": true,
      "inputs": [{"name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus"}],
      "path": "https://grafana.com/api/dashboards/7362/revisions/5/download"
    }'
  echo -e "\nMySQL dashboard imported!"
}

# Import Docker dashboard
import_docker_dashboard() {
  echo "Importing Docker dashboard..."
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/dashboards/import" \
    -d '{
      "dashboard": {"id": null, "uid": null, "title": "Docker Dashboard", "tags": ["docker", "prometheus"], "timezone": "browser", "schemaVersion": 16, "version": 0},
      "folderId": 0,
      "overwrite": true,
      "inputs": [{"name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus"}],
      "path": "https://grafana.com/api/dashboards/893/revisions/1/download"
    }'
  echo -e "\nDocker dashboard imported!"
}

# Create a custom application dashboard
create_app_dashboard() {
  echo "Creating application dashboard..."
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/dashboards/db" \
    -d '{
      "dashboard": {
        "id": null,
        "uid": null,
        "title": "React App Dashboard",
        "tags": ["react", "application"],
        "timezone": "browser",
        "schemaVersion": 16,
        "version": 0,
        "panels": [
          {
            "id": 1,
            "title": "HTTP Request Rate",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "rate(http_requests_total[5m])",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "HTTP Error Rate",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          },
          {
            "id": 3,
            "title": "Response Time",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "rate(http_response_time_seconds_sum[5m]) / rate(http_response_time_seconds_count[5m])",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
          }
        ]
      },
      "folderId": 0,
      "overwrite": true
    }'
  echo -e "\nApplication dashboard created!"
}

# Main function
main() {
  wait_for_grafana
  add_prometheus_datasource
  import_node_exporter_dashboard
  import_jenkins_dashboard
  import_mysql_dashboard
  import_docker_dashboard
  create_app_dashboard
  echo "Grafana dashboards setup complete!"
}

# Run the script
main