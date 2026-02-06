#!/bin/bash
set -euo pipefail

export admin_password=${admin_password}
export node_count=${node_count}

get_instance_metadata() {
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
}

main() {
    get_instance_metadata
    echo "Neo4j setup complete!"
}

main 