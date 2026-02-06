output "neo4j_http_url" {
  description = "URL to access Neo4j Browser via load balancer"
  value       = "http://${google_compute_global_address.neo4j.address}:7474"
}

output "neo4j_bolt_endpoint" {
  description = "Bolt endpoint for Neo4j connections via load balancer"
  value       = "bolt://${google_compute_global_address.neo4j.address}:7687"
}
