output "neo4j_urls" {
  description = "URLs to access Neo4j Browser"
  value = [
    for instance in google_compute_instance.neo4j : "http://${instance.network_interface[0].access_config[0].nat_ip}:7474"
  ]
}

output "neo4j_bolt_endpoints" {
  description = "Bolt endpoints for Neo4j connections"
  value = [
    for instance in google_compute_instance.neo4j : "bolt://${instance.network_interface[0].access_config[0].nat_ip}:7687"
  ]
}