#!/bin/bash
set -euo pipefail

echo Running startup script...

echo "Installing Graph Database..."
rpm --import https://debian.neo4j.com/neotechnology.gpg.key

cat <<EOF > /etc/yum.repos.d/neo4j.repo
[neo4j]
name=Neo4j RPM Repository
baseurl=https://yum.neo4j.com/stable/latest
enabled=1
gpgcheck=1
EOF

export NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
yum -y install neo4j-enterprise
systemctl enable neo4j

echo "Starting Neo4j..."
service neo4j start
neo4j-admin dbms set-initial-password "${password}"
