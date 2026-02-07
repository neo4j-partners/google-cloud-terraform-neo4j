






if [[ $nodeCount == 1 ]]; then
  echo "Running on a single node."
else
  echo "Running on multiple nodes.  Configuring membership in neo4j.conf..."

  COREMEMBERS=""
  INSTANCES=$(gcloud compute instance-groups list-instances neo4j-deployment-igm --region us-central1 --format="value(NAME)")
  for INSTANCE in $INSTANCES; do
    COREMEMBERS+=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name=( '$INSTANCE' )")
    COREMEMBERS+=":6000,"
  done
  echo $COREMEMBERS

  if [[ $${#COREMEMBERS} -eq 0 ]]; then
    echo "Missing coreMembers. Exiting"
  fi

  echo "dbms.cluster.endpoints=$COREMEMBERS" >> /etc/neo4j/neo4j.conf
fi


 - Required 'compute.instances.list' permission for 'projects/neo4jbusinessdev'
 - Required 'compute.regions.list' permission for 'projects/neo4jbusinessdev'



COREMEMBERS=""
INSTANCES=$(gcloud compute instance-groups list-instances neo4j-deployment-igm --region us-central1 --format="value(NAME)")
for INSTANCE in $INSTANCES; do
  COREMEMBERS+=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name=( '$INSTANCE' )")
  COREMEMBERS+=":6000,"
done
echo $COREMEMBERS

if [[ $${#COREMEMBERS} -eq 0 ]]; then
  echo "Missing coreMembers. Exiting"
fi
