#!/bin/bash
set -euo pipefail
echo Running startup script...\n"

#echo "Retrieving instance metadata..."
#export NODE_INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
#export NODE_EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
#export INSTANCE_NAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)

# Extract node index from instance name (neo4j-deployment_name-X format)
#export NODE_INDEX=$(echo $INSTANCE_NAME | sed 's/.*-//')
    
#echo "Metadata retrieved:"
#echo "NODE_INTERNAL_IP: $NODE_INTERNAL_IP"
#echo "NODE_EXTERNAL_IP: $NODE_EXTERNAL_IP"
#echo "INSTANCE_NAME: $INSTANCE_NAME"
#echo "NODE_INDEX: $NODE_INDEX"

install_neo4j_from_yum() {
  echo "Installing Graph Database..."
  rpm --import https://debian.neo4j.com/neotechnology.gpg.key
  echo "[neo4j]
name=Neo4j RPM Repository
baseurl=https://yum.neo4j.com/stable/latest
enabled=1
gpgcheck=1" > /etc/yum.repos.d/neo4j.repo
  export NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
  yum -y install neo4j-enterprise
  systemctl enable neo4j
}

start_neo4j() {
  echo "Starting Neo4j..."
  service neo4j start
  neo4j-admin dbms set-initial-password "${password}"
}

install_neo4j_from_yum
start_neo4j
