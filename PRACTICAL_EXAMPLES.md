# X-Terraform Agent Practical Examples - GCP Edition

## Overview

This document provides practical examples of how to interact with the X-Terraform Agent for Google Cloud Platform infrastructure development. Each example includes the prompt, expected response, and key capabilities demonstrated.

## Example Categories

### 1. Basic Module Generation

#### Example 1.1: Create a Simple GCP VPC

**Prompt:**
```
Create a basic Google Cloud VPC module with 2 public and 2 private subnets, 
firewall rules for HTTP/HTTPS, and proper tagging.
```

**Expected Response:**
```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "public" {
  count         = 2
  name          = "${var.network_name}-public-${count.index + 1}"
  ip_cidr_range = var.public_subnet_ranges[count.index]
  region        = var.regions[count.index]
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private" {
  count         = 2
  name          = "${var.network_name}-private-${count.index + 1}"
  ip_cidr_range = var.private_subnet_ranges[count.index]
  region        = var.regions[count.index]
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "https" {
  name    = "${var.network_name}-allow-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}
```

**Capabilities Demonstrated:**
- ✅ Basic resource creation
- ✅ Variable usage
- ✅ Conditional logic
- ✅ Proper naming conventions
- ✅ Security considerations

#### Example 1.2: Create a GKE Cluster

**Prompt:**
```
Create a Google Kubernetes Engine cluster with private nodes, 
autoscaling node pool, and workload identity enabled.
```

**Expected Response:**
```hcl
# main.tf
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.location
  cluster    = google_container_cluster.primary.name
  node_count = var.initial_node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/compute"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
```

### 2. Code Review and Analysis

#### Example 2.1: Security Review

**Prompt:**
```
Review this Terraform configuration for security issues and compliance with GCP best practices.
```

**Expected Response:**
```
🔍 Security Analysis Report

✅ Strengths:
- Private GKE cluster configuration
- Workload identity enabled
- Shielded instances configured
- Proper IAM roles assigned

⚠️ Issues Found:
1. SSH access is open to 0.0.0.0/0 - should restrict to specific IPs
2. Missing VPC Flow Logs for network monitoring
3. No encryption at rest for persistent disks
4. Missing network policies for pod-to-pod communication

🔧 Recommendations:
1. Restrict SSH access to specific CIDR blocks
2. Enable VPC Flow Logs for audit compliance
3. Configure encryption for persistent disks
4. Implement network policies for pod security
5. Add Cloud Armor for DDoS protection

📋 Compliance Checklist:
- [ ] CIS GCP Foundation Benchmark
- [ ] SOC 2 Type II requirements
- [ ] GDPR data protection
- [ ] Network security policies
```

#### Example 2.2: Performance Optimization

**Prompt:**
```
Analyze this GKE cluster configuration for performance optimization opportunities.
```

**Expected Response:**
```
🚀 Performance Optimization Analysis

Current Configuration:
- Node count: 3 nodes
- Machine type: e2-standard-2
- Disk size: 100GB
- Autoscaling: Enabled (1-5 nodes)

📊 Optimization Opportunities:

1. **Node Pool Optimization:**
   - Consider using e2-standard-4 for better CPU/memory ratio
   - Implement node taints for workload separation
   - Use spot instances for non-critical workloads

2. **Storage Optimization:**
   - Use SSD persistent disks for better I/O performance
   - Implement storage classes for different workload types
   - Consider using Filestore for shared storage

3. **Network Optimization:**
   - Enable VPC-native clusters for better networking
   - Use regional clusters for lower latency
   - Implement proper pod anti-affinity rules

4. **Cost Optimization:**
   - Use committed use discounts for predictable workloads
   - Implement proper resource requests and limits
   - Use preemptible nodes for batch processing

💰 Estimated Cost Savings: 20-30% with optimizations
```

### 3. Troubleshooting and Debugging

#### Example 3.1: Fix Configuration Error

**Prompt:**
```
I'm getting this error: "Error: google_container_cluster.primary: 
Invalid value for field 'master_ipv4_cidr_block': must be a valid CIDR block". 
How do I fix this?
```

**Expected Response:**
```
🔧 Error Analysis and Fix

**Error Cause:**
The `master_ipv4_cidr_block` value is not a valid CIDR block format.

**Current Configuration:**
```hcl
private_cluster_config {
  master_ipv4_cidr_block = "172.16.0.0"  # ❌ Invalid
}
```

**Solution:**
```hcl
private_cluster_config {
  master_ipv4_cidr_block = "172.16.0.0/28"  # ✅ Valid CIDR
}
```

**Explanation:**
- CIDR blocks must include the subnet mask (e.g., /28)
- For GKE private clusters, use /28 for small clusters
- Available ranges: 172.16.0.0/28, 172.16.0.16/28, etc.

**Additional Recommendations:**
1. Ensure the CIDR doesn't overlap with your VPC subnets
2. Use /28 for up to 16 nodes, /27 for up to 32 nodes
3. Consider using 10.0.0.0/28 for better IP management
```

#### Example 3.2: Network Connectivity Issues

**Prompt:**
```
My GKE pods can't reach external services. The cluster is in a private VPC. 
What's wrong and how do I fix it?
```

**Expected Response:**
```
🌐 Network Connectivity Analysis

**Problem:** Private GKE cluster without NAT gateway

**Root Cause:**
Private nodes in GKE clusters cannot reach external services without a NAT gateway.

**Solution:**
```hcl
# Add Cloud Router
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.location
  network = google_compute_network.vpc.id
}

# Add Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
```

**Alternative Solutions:**
1. Use Cloud NAT for all private subnets
2. Configure proxy servers for specific services
3. Use VPC peering for internal service communication

**Cost Impact:**
- Cloud NAT: ~$0.045/hour per region
- Consider using NAT instances for development environments
```

### 4. Advanced Module Enhancement

#### Example 4.1: Add Monitoring and Logging

**Prompt:**
```
Enhance this GKE cluster with comprehensive monitoring, logging, and alerting.
```

**Expected Response:**
```hcl
# Enhanced GKE cluster with monitoring

# Enable monitoring
resource "google_monitoring_cluster_istio_service" "default" {
  service_name = "kubernetes.io/istio/service"
  location     = var.location
  cluster_name = google_container_cluster.primary.name
}

# Logging configuration
resource "google_logging_project_sink" "gke_logs" {
  name        = "gke-logs-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.logs.name}"
  filter      = "resource.type=\"k8s_container\""
}

# Alerting policies
resource "google_monitoring_alert_policy" "gke_high_cpu" {
  display_name = "GKE High CPU Usage"
  combiner     = "OR"

  conditions {
    display_name = "High CPU Usage"
    condition_threshold {
      filter     = "metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
      duration   = "300s"
      comparison = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Dashboard
resource "google_monitoring_dashboard" "gke_dashboard" {
  dashboard_json = jsonencode({
    displayName = "GKE Cluster Dashboard"
    gridLayout = {
      widgets = [
        {
          title = "CPU Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                }
              }
            }]
          }
        }
      ]
    }
  })
}
```

#### Example 4.2: Security Hardening

**Prompt:**
```
Enhance this VPC module with advanced security features including 
Cloud Armor, VPC Flow Logs, and network policies.
```

**Expected Response:**
```hcl
# Enhanced VPC with security features

# VPC Flow Logs
resource "google_compute_subnetwork" "public" {
  # ... existing configuration ...

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Armor security policy
resource "google_compute_security_policy" "policy" {
  name = "${var.network_name}-security-policy"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny access by default"
  }

  rule {
    action   = "allow"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_ip_ranges
      }
    }
    description = "Allow access from trusted IPs"
  }
}

# Network firewall policy
resource "google_compute_network_firewall_policy" "default" {
  name = "${var.network_name}-firewall-policy"
}

resource "google_compute_network_firewall_policy_rule" "default" {
  name                    = "default-rule"
  firewall_policy         = google_compute_network_firewall_policy.default.name
  priority                = 1000
  enable_logging          = true
  action                  = "deny"
  direction               = "INGRESS"
  match {
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["22", "3389"]
    }
    src_ip_ranges = ["0.0.0.0/0"]
  }
}
```

### 5. Documentation Generation

#### Example 5.1: Generate Module Documentation

**Prompt:**
```
Generate comprehensive documentation for this GCP VPC module including 
usage examples, security considerations, and troubleshooting guide.
```

**Expected Response:**
```markdown
# GCP VPC Module

## Overview
This Terraform module creates a secure VPC network in Google Cloud Platform with public and private subnets, NAT gateway, and comprehensive firewall rules.

## Features
- ✅ Multi-region VPC with public and private subnets
- ✅ Cloud NAT for private subnet internet access
- ✅ Comprehensive firewall rules
- ✅ VPC Flow Logs for network monitoring
- ✅ Proper IAM and security configurations

## Usage

### Basic Usage
```hcl
module "vpc" {
  source = "./gcp-vpc"

  project_id = "my-project-123"
  network_name = "production-vpc"
  
  public_subnet_ranges  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_ranges = ["10.0.10.0/24", "10.0.11.0/24"]
  
  regions = ["us-central1", "us-west1"]
  
  enable_nat = true
  enable_flow_logs = true
}
```

### Advanced Usage
```hcl
module "vpc" {
  source = "./gcp-vpc"

  project_id = "my-project-123"
  network_name = "secure-vpc"
  
  # Custom CIDR ranges
  vpc_cidr_block = "172.16.0.0/16"
  public_subnet_ranges  = ["172.16.1.0/24", "172.16.2.0/24"]
  private_subnet_ranges = ["172.16.10.0/24", "172.16.11.0/24"]
  
  # Security configurations
  enable_nat = true
  enable_flow_logs = true
  ssh_source_ranges = ["203.0.113.0/24"]  # Restrict SSH access
  
  # Tags
  common_tags = {
    Environment = "production"
    Project     = "web-application"
    Team        = "platform"
  }
}
```

## Security Considerations

### Network Security
- Private subnets have no direct internet access
- NAT gateway provides controlled internet access
- Firewall rules restrict traffic appropriately
- VPC Flow Logs enable network monitoring

### Access Control
- SSH access should be restricted to specific IP ranges
- Use IAM roles for service account access
- Implement least privilege principle

### Compliance
- Meets CIS GCP Foundation Benchmark requirements
- Supports SOC 2 Type II compliance
- Enables GDPR data protection measures

## Troubleshooting

### Common Issues

1. **NAT Gateway Not Working**
   - Ensure Cloud Router is created
   - Check IAM permissions for NAT service
   - Verify subnet configurations

2. **Firewall Rules Not Applied**
   - Check target tags on instances
   - Verify source IP ranges
   - Ensure rules have proper priority

3. **VPC Flow Logs Not Appearing**
   - Check IAM permissions for logging
   - Verify log export configuration
   - Ensure proper billing setup

## Cost Optimization

### Recommendations
- Use Cloud NAT sparingly (costs ~$0.045/hour)
- Consider NAT instances for development
- Monitor VPC Flow Logs storage costs
- Use appropriate machine types for workloads

### Estimated Costs
- VPC: Free
- Cloud NAT: ~$32/month per region
- VPC Flow Logs: ~$5-15/month depending on traffic
- Firewall rules: Free

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP Project ID | string | - | yes |
| network_name | VPC network name | string | "my-vpc" | no |
| vpc_cidr_block | VPC CIDR block | string | "10.0.0.0/16" | no |
| public_subnet_ranges | Public subnet CIDR ranges | list(string) | ["10.0.1.0/24", "10.0.2.0/24"] | no |
| private_subnet_ranges | Private subnet CIDR ranges | list(string) | ["10.0.10.0/24", "10.0.11.0/24"] | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VPC network ID |
| network_name | VPC network name |
| public_subnet_ids | Public subnet IDs |
| private_subnet_ids | Private subnet IDs |
| nat_gateway_id | Cloud NAT gateway ID |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | ~> 5.0 |

## License

MIT License
```

## Best Practices for Using the Agent

### 1. Be Specific in Prompts
**Good:** "Create a GKE cluster with private nodes and autoscaling"
**Bad:** "Create a Kubernetes cluster"

### 2. Include Requirements
**Good:** "Create a VPC module that supports multi-region deployment and includes monitoring"
**Bad:** "Create a VPC"

### 3. Ask for Reviews
**Good:** "Review this configuration for security issues and cost optimization"
**Bad:** "Check this"

### 4. Request Documentation
**Good:** "Generate comprehensive documentation with usage examples and troubleshooting"
**Bad:** "Add docs"

### 5. Iterate and Enhance
**Good:** "Enhance this module with advanced security features and monitoring"
**Bad:** "Make it better"

## Conclusion

The X-Terraform Agent provides powerful capabilities for GCP infrastructure development. By following these examples and best practices, users can:

1. **Accelerate Development**: Generate production-ready modules quickly
2. **Ensure Security**: Follow best practices and security guidelines
3. **Optimize Costs**: Get recommendations for cost optimization
4. **Maintain Quality**: Generate comprehensive documentation
5. **Troubleshoot Issues**: Get specific guidance for common problems

The agent's offline capabilities and deep knowledge of HashiCorp Terraform best practices make it an invaluable tool for infrastructure as code development on Google Cloud Platform. 