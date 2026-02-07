provider "google" {
  project = var.project_id
}

resource "google_compute_instance" "neo4j" {
  name         = "${var.goog_cm_deployment_name}-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.source_image
      size  = var.disk_size
      type  = "hyperdisk-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    password  = var.password
  })
}

resource "google_compute_firewall" "neo4j" {
  name    = "${var.goog_cm_deployment_name}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["7474", "7687"]
  }

  source_ranges = ["0.0.0.0/0"]
}
