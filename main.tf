provider "google" {
  project = "terraformtesting-473007"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "tf-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "tf-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# Firewall (like Security Group)
resource "google_compute_firewall" "allow_ssh_http" {
  name    = "allow-ssh-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# VM Instance
resource "google_compute_instance" "vm" {
  name         = "tf-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10   # lowest safe
      type  = "pd-standard"  # cheaper than SSD
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {} # ephemeral public IP (FREE)
  }

  metadata_startup_script = <<EOF
    #!/bin/bash

    echo "STARTED" > /tmp/startup.log

    apt-get update -y
    apt-get install -y nginx

    systemctl enable nginx
    systemctl start nginx

    echo "DONE" >> /tmp/startup.log
   EOF

  tags = ["web"]
}