echo "Configuring network in neo4j.conf..."
sed -i "s/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g" /etc/neo4j/neo4j.conf
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

if [[ $nodeCount == 1 ]]; then
  echo "Running on a single node."
else
  echo "Running on multiple nodes.  Configuring membership in neo4j.conf..."
  local PRIVATEIP="$(hostname -i | awk '{print $NF}')"
  sed -i s/#server.cluster.listen_address=:6000/server.cluster.listen_address=0.0.0.0:6000/g /etc/neo4j/neo4j.conf
  sed -i s/#server.cluster.advertised_address=:6000/server.cluster.advertised_address=$PRIVATEIP:6000/g /etc/neo4j/neo4j.conf
  sed -i s/#server.cluster.raft.listen_address=:7000/server.cluster.raft.listen_address=0.0.0.0:7000/g /etc/neo4j/neo4j.conf
  sed -i s/#server.cluster.raft.advertised_address=:7000/server.cluster.raft.advertised_address=$PRIVATEIP:7000/g /etc/neo4j/neo4j.conf
  sed -i s/#server.routing.listen_address=0.0.0.0:7688/server.routing.listen_address=0.0.0.0:7688/g /etc/neo4j/neo4j.conf
  sed -i s/#server.routing.advertised_address=:7688/server.routing.advertised_address=$PRIVATEIP:7688/g /etc/neo4j/neo4j.conf
  sed -i s/#initial.dbms.default_primaries_count=1/initial.dbms.default_primaries_count=3/g /etc/neo4j/neo4j.conf
  sed -i s/#initial.dbms.default_secondaries_count=0/initial.dbms.default_secondaries_count=$(expr $nodeCount - 3)/g /etc/neo4j/neo4j.conf
  echo "dbms.cluster.minimum_initial_system_primaries_count=$nodeCount" >> /etc/neo4j/neo4j.conf

  COREMEMBERS=""
  INSTANCES=$(gcloud compute instance-groups list-instances neo4j-deployment-mig --region us-central1 --format="value(NAME)")
  for INSTANCE in $INSTANCES; do
    COREMEMBERS+=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name=( '$INSTANCE' )")
    COREMEMBERS+=":6000,"
  done
  echo $COREMEMBERS

  if [[ $${#COREMEMBERS} -eq 0 ]]; then
    echo "Missing coreMembers. Exiting"
  fi

  echo "dbms.cluster.discovery.resolver_type=LIST" >> /etc/neo4j/neo4j.conf
  echo "dbms.cluster.endpoints=$COREMEMBERS" >> /etc/neo4j/neo4j.conf
fi
