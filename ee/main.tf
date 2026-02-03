provider "google" {
  project = var.project_id
}

locals {
  network_interfaces = [ for i, n in var.networks : {
    network     = n,
    subnetwork  = length(var.sub_networks) > i ? element(var.sub_networks, i) : null
    external_ip = length(var.external_ips) > i ? element(var.external_ips, i) : "NONE"
    }
  ]
  metadata = {
  }
}

resource "google_compute_instance" "instance" {
  name = "${var.goog_cm_deployment_name}-vm"
  machine_type = var.machine_type
  zone = var.zone

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

  metadata_startup_script = templatefile("${path.module}/scripts/startup.sh", {
    node_count        = var.node_count
    node_index        = count.index + 1
    admin_password    = var.admin_password
    install_bloom     = var.install_bloom ? "Yes" : "No"
    bloom_license_key = var.bloom_license_key
    deployment_name   = var.deployment_name
    project_id        = var.project_id
    license_type      = var.license_type
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