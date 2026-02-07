variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

// Marketplace requires this variable name to be declared
variable "goog_cm_deployment_name" {
  description = "The name of the deployment and VM instance."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created"
  type        = string
}

variable "zones" {
  description = "The GCP zones where resources will be created"
  type        = list(string)
}

variable "password" {
  description = "Password for Neo4j"
  type        = string
}

variable "node_count" {
  description = "Number of Neo4j instances to deploy"
  type        = number
  validation {
    condition     = contains([1, 3], var.node_count)
    error_message = "Node count must be 1 or 3."
  }
  default = 3
}

variable "machine_type" {
  description = "GCP machine type for Neo4j nodes"
  type        = string
  default     = "n4-standard-4"
}

variable "disk_size" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 100
}

variable "source_image" {
  description = "Base image for the VM instance."
  type        = string
  default     = "projects/centos-cloud/global/images/centos-stream-10-v20260126"
  #default     = "projects/neo4j-mp-public/global/images/neo4j-enterprise-edition"
}
