provider "google" {
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
}
