// Marketplace requires this variable name to be declared
variable "goog_cm_deployment_name" {
  description = "The name of the deployment and VM instance."
  type        = string
}

#### Network Variables

variable "networks" {
  description = "The network name to attach the VM instance."
  type        = list(string)
  default     = ["default"]
}

variable "sub_networks" {
  description = "The sub network name to attach the VM instance."
  type        = list(string)
  default     = []
}

variable "external_ips" {
  description = "The external IPs assigned to the VM for public access."
  type        = list(string)
  default     = ["EPHEMERAL"]
}


#### VM Variables

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
  default     = "c3-standard-4"
}

variable "zone" {
  description = "The GCP zone where resources will be created"
  type        = string
}

variable "disk_size" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 100
}

variable "source_image" {
  description = "Base image for the VM instance."
  type        = string
  default     = "projects/neo4j-mp-public/global/images/neo4j-enterprise-edition"
}
