#!/bin/bash
set -euo pipefail

echo Running startup script...
export password="${password}"

install_neo4j_from_yum() {
  echo "Installing Graph Database..."
  rpm --import https://debian.neo4j.com/neotechnology.gpg.key
  echo "[neo4j]
name=Neo4j RPM Repository
baseurl=https://yum.neo4j.com/stable/latest
enabled=1
gpgcheck=1" > /etc/yum.repos.d/neo4j.repo
  yum -y install neo4j
  systemctl enable neo4j
}

build_neo4j_conf_file() {
  echo "Configuring network in neo4j.conf..."
  sed -i "s/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g" /etc/neo4j/neo4j.conf

  PUBLICIP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)








  sed -i "s/#server.default_advertised_address=localhost/server.default_advertised_address=$loadBalancerIP/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.bolt.listen_address=:7687/server.bolt.listen_address=0.0.0.0:7687/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.bolt.advertised_address=:7687/server.bolt.advertised_address=$loadBalancerIP:7687/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.http.listen_address=:7474/server.http.listen_address=0.0.0.0:7474/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.http.advertised_address=:7474/server.http.advertised_address=$loadBalancerIP:7474/g" /etc/neo4j/neo4j.conf
  neo4j-admin server memory-recommendation >> /etc/neo4j/neo4j.conf
  echo "server.metrics.enabled=true" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.jmx.enabled=true" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.prefix=neo4j" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.filter=*" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.csv.interval=5s" >> /etc/neo4j/neo4j.conf
  echo "dbms.routing.default_router=SERVER" >> /etc/neo4j/neo4j.conf
}

add_cypher_ip_blocklist() {
  echo "internal.dbms.cypher_ip_blocklist=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.169.0/24,fc00::/7,fe80::/10,ff00::/8" >> /etc/neo4j/neo4j.conf
}

start_neo4j() {
  echo "Starting Neo4j..."
  neo4j-admin dbms set-initial-password "$password"

  # service neo4j start
  # The service wrapper is failing.  Instead, let's try starting directly.
  /usr/bin/neo4j start

}

install_neo4j_from_yum
build_neo4j_conf_file
add_cypher_ip_blocklist
start_neo4j
