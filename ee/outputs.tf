output "neo4j_http_url" {
  description = "URL to access Neo4j Browser via load balancer"
  value       = "http://${google_compute_global_address.neo4j_http.address}"
}

output "neo4j_bolt_endpoint" {
  description = "Bolt endpoint for Neo4j connections via load balancer"
  value       = "bolt://${google_compute_address.neo4j_bolt.address}:7687"
}

output "neo4j_mig_name" {
  description = "Name of the managed instance group"
  value       = google_compute_instance_group_manager.neo4j.name
}

output "neo4j_mig_instances" {
  description = "Instances in the managed instance group"
  value       = google_compute_instance_group_manager.neo4j.managed_instances
}