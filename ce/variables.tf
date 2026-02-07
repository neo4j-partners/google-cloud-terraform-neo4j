// Marketplace requires this variable name to be declared
variable "goog_cm_deployment_name" {
  description = "The name of the deployment and VM instance."
  type        = string
}

variable "zone" {
  description = "The GCP zone where resources will be created"
  type        = string
}

variable "password" {
  description = "Password for Neo4j"
  type        = string
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
  default     = "projects/neo4j-mp-public/global/images/neo4j-community-edition"
}
