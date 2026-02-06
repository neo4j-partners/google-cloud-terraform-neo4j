#!/bin/bash
set -euo pipefail
echo Running startup script...\n"

export password=${password}
export nodeCount=${node_count}

echo "Retrieving instance metadata..."
export NODE_INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
export NODE_EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
export INSTANCE_NAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)

# Extract node index from instance name (neo4j-deployment_name-X format)
export NODE_INDEX=$(echo $INSTANCE_NAME | sed 's/.*-//')
    
# Print the values to verify
echo "Metadata retrieved:"
echo "NODE_INTERNAL_IP: $NODE_INTERNAL_IP"
echo "NODE_EXTERNAL_IP: $NODE_EXTERNAL_IP"
echo "INSTANCE_NAME: $INSTANCE_NAME"
echo "NODE_INDEX: $NODE_INDEX"

loadBalancerDNSName="foo"

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

extension_config() {
  echo Configuring extensions and security in neo4j.conf...
  sed -i s~#server.unmanaged_extension_classes=org.neo4j.examples.server.unmanaged=/examples/unmanaged~server.unmanaged_extension_classes=com.neo4j.bloom.server=/bloom,semantics.extension=/rdf~g /etc/neo4j/neo4j.conf
  sed -i s/#dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*/dbms.security.procedures.unrestricted=gds.*,apoc.*,bloom.*/g /etc/neo4j/neo4j.conf
  echo \"dbms.security.http_auth_allowlist=/,/browser.*,/bloom.*\" >> /etc/neo4j/neo4j.conf
  echo \"dbms.security.procedures.allowlist=apoc.*,gds.*,bloom.*\" >> /etc/neo4j/neo4j.conf
}

build_neo4j_conf_file() {
  local -r privateIP=\"$(hostname -i | awk '{print $NF}')\"
  echo "Configuring network in neo4j.conf..."
  sed -i 's/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g' /etc/neo4j/neo4j.conf
  sed -i s/#server.default_advertised_address=localhost/server.default_advertised_address="${loadBalancerDNSName}"/g /etc/neo4j/neo4j.conf
  sed -i s/#server.bolt.listen_address=:7687/server.bolt.listen_address=0.0.0.0:7687/g /etc/neo4j/neo4j.conf
  sed -i s/#server.bolt.advertised_address=:7687/server.bolt.advertised_address="${loadBalancerDNSName}":7687/g /etc/neo4j/neo4j.conf
  sed -i s/#server.http.listen_address=:7474/server.http.listen_address=0.0.0.0:7474/g /etc/neo4j/neo4j.conf
  sed -i s/#server.http.advertised_address=:7474/server.http.advertised_address="${loadBalancerDNSName}":7474/g /etc/neo4j/neo4j.conf
  neo4j-admin server memory-recommendation >> /etc/neo4j/neo4j.conf
  echo "server.metrics.enabled=true\" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.jmx.enabled=true\" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.prefix=neo4j\" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.filter=*\" >> /etc/neo4j/neo4j.conf
  echo "server.metrics.csv.interval=5s\" >> /etc/neo4j/neo4j.conf
  echo "dbms.routing.default_router=SERVER\" >> /etc/neo4j/neo4j.conf

  if [[ ${nodeCount} == 1 ]]; then
    echo "Running on a single node."
  else
    echo "Running on multiple nodes.  Configuring membership in neo4j.conf..."
    sed -i s/#server.cluster.listen_address=:6000/server.cluster.listen_address=0.0.0.0:6000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.cluster.advertised_address=:6000/server.cluster.advertised_address=\"${privateIP}\":6000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.cluster.raft.listen_address=:7000/server.cluster.raft.listen_address=0.0.0.0:7000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.cluster.raft.advertised_address=:7000/server.cluster.raft.advertised_address=\"${privateIP}\":7000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.routing.listen_address=0.0.0.0:7688/server.routing.listen_address=0.0.0.0:7688/g /etc/neo4j/neo4j.conf
    sed -i s/#server.routing.advertised_address=:7688/server.routing.advertised_address=\"${privateIP}\":7688/g /etc/neo4j/neo4j.conf
    sed -i s/#initial.dbms.default_primaries_count=1/initial.dbms.default_primaries_count=3/g /etc/neo4j/neo4j.conf
    sed -i s/#initial.dbms.default_secondaries_count=0/initial.dbms.default_secondaries_count=$(expr ${nodeCount} - 3)/g /etc/neo4j/neo4j.conf
    echo "dbms.cluster.minimum_initial_system_primaries_count=${nodeCount}" >> /etc/neo4j/neo4j.conf



    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    instanceId=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
    if [[ ${instanceId} -eq 0 ]]; then
      echo "Missing instance ID. Exiting."
    fi
#    coreMembers=$(aws autoscaling describe-auto-scaling-instances --region $region --output text --query "AutoScalingInstances[?contains(AutoScalingGroupName,'$stackName-Neo4jAutoScalingGroup')].[InstanceId]" | xargs -n1 -I {} aws ec2 describe-instances --instance-ids {} --region $region --query "Reservations[].Instances[].PrivateIpAddress" --output text --filter "Name=tag:aws:cloudformation:stack-name,Values=$stackName")

    if [[ ${coreMembers} -eq 0 ]]; then
     echo "Missing coreMembers. Exiting!!!"
    fi
    echo "CoreMembers = ${coreMembers}"
    coreMembers=$(echo ${coreMembers} | sed 's/ /:6000,/g')
    coreMembers=$(echo "${coreMembers}"):6000
    echo "dbms.cluster.discovery.resolver_type=LIST" >> /etc/neo4j/neo4j.conf
    echo "dbms.cluster.endpoints=${coreMembers}" >> /etc/neo4j/neo4j.conf
  fi
}

add_cypher_ip_blocklist() {
  echo "internal.dbms.cypher_ip_blocklist=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.169.0/24,fc00::/7,fe80::/10,ff00::/8" >> /etc/neo4j/neo4j.conf
}

start_neo4j() {
  echo "Starting Neo4j..."
  service neo4j start
  neo4j-admin dbms set-initial-password "${password}"
}

install_neo4j_from_yum
#extension_config
#build_neo4j_conf_file
#add_cypher_ip_blocklist
#start_neo4j
