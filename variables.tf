variable "project_id" {
  description = "The GCP project ID"
  type        = string
  # Issue: No default value or validation
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
  
  # Issue: No validation for allowed values
  # validation {
  #   condition     = contains(["dev", "staging", "production"], var.environment)
  #   error_message = "Environment must be dev, staging, or production."
  # }
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "network_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  # Issue: No validation for CIDR format
  # validation {
  #   condition     = can(cidrhost(var.network_cidr, 0))
  #   error_message = "Must be a valid CIDR block."
  # }
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type        = map(string)
  default = {
    private = "10.0.1.0/24"
    public  = "10.0.2.0/24"
  }
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "production-cluster"
}

variable "database_name" {
  description = "Name of the Cloud SQL database"
  type        = string
  default     = "production-db"
}

# Issue: Missing important variables
# variable "node_count" {
#   description = "Number of nodes in the GKE cluster"
#   type        = number
#   default     = 3
# }

# variable "machine_type" {
#   description = "Machine type for GKE nodes"
#   type        = string
#   default     = "e2-standard-2"
# }

# variable "disk_size_gb" {
#   description = "Disk size for GKE nodes"
#   type        = number
#   default     = 100
# } 