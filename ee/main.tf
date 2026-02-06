provider "google" {
}

locals {
  network_interfaces = [ for i, n in var.networks : {
    network     = n,
    subnetwork  = length(var.sub_networks) > i ? element(var.sub_networks, i) : null
    external_ip = length(var.external_ips) > i ? element(var.external_ips, i) : "NONE"
    }
  ]
}

resource "google_compute_instance" "neo4j" {
  count        = var.node_count
  name         = "${var.goog_cm_deployment_name}-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["${var.goog_cm_deployment_name}-deployment"]

  boot_disk {
    device_name = "solution-vm-tmpl-boot-disk"

    initialize_params {
      size = var.disk_size
      type = "pd-ssd"
      image = var.source_image
    }
  }

  metadata = {}

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    password          = "foobar123"
    node_count        = var.node_count
  })

  dynamic "network_interface" {
    for_each = local.network_interfaces
    content {
      network = network_interface.value.network
      subnetwork = network_interface.value.subnetwork

      dynamic "access_config" {
        for_each = network_interface.value.external_ip == "NONE" ? [] : [1]
        content {
          nat_ip = network_interface.value.external_ip == "EPHEMERAL" ? null : network_interface.value.external_ip
        }
      }
    }
  }
}
