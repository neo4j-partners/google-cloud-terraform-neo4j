#!/bin/bash
set -euo pipefail

#!/bin/bash
set -euo pipefail

echo Running startup script...
export password="${password}"
export nodeCount="${nodeCount}"
export goog_cm_deployment_name="${goog_cm_deployment_name}"

echo "Installing Graph Database..."
rpm --import https://debian.neo4j.com/neotechnology.gpg.key
echo "[neo4j]
name=Neo4j RPM Repository
baseurl=https://yum.neo4j.com/stable/latest
enabled=1
gpgcheck=1" > /etc/yum.repos.d/neo4j.repo
export NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
yum -y install neo4j-enterprise

echo "Configuring network in neo4j.conf..."
sed -i "s/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g" /etc/neo4j/neo4j.conf

if [[ $nodeCount == 1 ]]; then
  echo "Running on a single node."
else
  echo "Running on multiple nodes.  Configuring membership in neo4j.conf..."

  COREMEMBERS=""
  #### Deployment name is currently hardcoded.  Need to come back and clean this up.
  INSTANCES=$(gcloud compute instance-groups list-instances neo4j-tf-instance-group-manager --region us-central1 --format="value(NAME)")
  for INSTANCE in $INSTANCES; do
    COREMEMBERS+=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name=( '$INSTANCE' )")
    COREMEMBERS+=":6000,"
  done
  COREMEMBERS=$${COREMEMBERS::-1}
  echo $COREMEMBERS

  if [[ $${#COREMEMBERS} -eq 0 ]]; then
    echo "Missing coreMembers. Exiting"
    exit 1
  fi

  sed -i "s/#dbms.cluster.endpoints=localhost:6000,localhost:6001,localhost:6002/dbms.cluster.endpoints=$COREMEMBERS/g" /etc/neo4j/neo4j.conf
fi

echo "Starting Neo4j..."
neo4j-admin dbms set-initial-password "$password"
systemctl enable neo4j
/usr/bin/neo4j start
