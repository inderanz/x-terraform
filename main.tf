# Production GCP Infrastructure with Common Issues
# This represents a real-world scenario with security, networking, and configuration problems

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Issue 1: Missing project variable - will cause error
provider "google" {
  region = "us-central1"
  # project = var.project_id  # This is commented out - will cause issues
}

# Issue 2: VPC with overly permissive firewall rules
resource "google_compute_network" "vpc" {
  name                    = "production-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
  region        = "us-central1"
  
  # Issue: Missing private Google access
  # private_ip_google_access = true
}

resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc.id
  region        = "us-central1"
}

# Issue 3: Overly permissive firewall rule
resource "google_compute_firewall" "allow_all" {
  name    = "allow-all-traffic"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]  # This is a security risk!
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]  # This is also a security risk!
  }

  source_ranges = ["0.0.0.0/0"]  # This allows traffic from anywhere!
}

# Issue 4: GKE cluster with security issues
resource "google_container_cluster" "primary" {
  name     = "production-cluster"
  location = "us-central1"

  # Issue: Using default node pool instead of separate node pools
  remove_default_node_pool = false
  initial_node_count       = 1

  # Issue: Missing network policy
  # network_policy {
  #   enabled = true
  # }

  # Issue: Missing pod security policy
  # pod_security_policy_config {
  #   enabled = true
  # }

  # Issue: Missing workload identity
  # workload_identity_config {
  #   workload_pool = "${var.project_id}.svc.id.goog"
  # }

  # Issue: Missing maintenance window
  # maintenance_policy {
  #   daily_maintenance_window {
  #     start_time = "03:00"
  #   }
  # }

  # Issue: Missing release channel
  # release_channel {
  #   channel = "REGULAR"
  # }
}

# Issue 5: Cloud SQL with security issues
resource "google_sql_database_instance" "instance" {
  name             = "production-db"
  database_version = "POSTGRES_14"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"  # Issue: Too small for production

    # Issue: Missing backup configuration
    # backup_configuration {
    #   enabled    = true
    #   start_time = "02:00"
    # }

    # Issue: Missing maintenance window
    # maintenance_window {
    #   day          = 7
    #   hour         = 2
    #   update_track = "stable"
    # }

    # Issue: Missing IP configuration
    # ip_configuration {
    #   ipv4_enabled    = false
    #   private_network = google_compute_network.vpc.id
    # }
  }

  # Issue: Missing deletion protection
  # deletion_protection = true
}

# Issue 6: IAM with overly broad permissions
resource "google_project_iam_member" "project" {
  project = "my-project-id"  # Issue: Hardcoded project ID
  role    = "roles/owner"    # Issue: Too broad permission
  member  = "user:admin@example.com"
}

# Issue 7: Missing monitoring and logging
# resource "google_logging_project_sink" "log_sink" {
#   name        = "production-logs"
#   destination = "storage.googleapis.com/${google_storage_bucket.log_bucket.name}"
#   filter      = "resource.type = gce_instance"
# }

# Issue 8: Missing cost optimization
resource "google_compute_instance" "app_server" {
  name         = "app-server"
  machine_type = "e2-standard-4"  # Issue: Not using committed use discounts
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50  # Issue: Too large for the workload
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    
    # Issue: Missing access config for private instances
    # access_config {
    #   // Ephemeral public IP
    # }
  }

  # Issue: Missing metadata for startup scripts
  # metadata = {
  #   startup-script = file("${path.module}/startup.sh")
  # }

  # Issue: Missing service account
  # service_account {
  #   scopes = ["cloud-platform"]
  # }
}

# Issue 9: Missing variables file
# variables.tf should define:
# - var.project_id
# - var.environment
# - var.region
# - var.network_cidr
# - var.subnet_cidrs

# Issue 10: Missing outputs
# outputs.tf should define:
# - cluster_endpoint
# - database_connection_name
# - vpc_self_link 