#!/bin/bash
set -euo pipefail
echo Running startup script...\n"

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
