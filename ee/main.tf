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

resource "google_compute_instance_template" "neo4j" {
  name_prefix = "${var.goog_cm_deployment_name}-tmpl-"
  description = "Instance template for Neo4j"
  machine_type = var.machine_type

  tags = ["${var.goog_cm_deployment_name}-deployment", "neo4j"]

  disk {
    auto_delete  = true
    boot         = true
    source_image = var.source_image
    disk_size_gb = var.disk_size
    disk_type    = "pd-ssd"
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    password   = "foobar123"
    nodeCount = var.node_count
    loadBalancerDNSName = "${google_compute_global_address.neo4j_http.address}"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "neo4j" {
  name               = "${var.goog_cm_deployment_name}-health-check"
  check_interval_sec = 10
  timeout_sec        = 5

  http_health_check {
    port = "7474"
    request_path = "/"
  }
}

resource "google_compute_instance_group_manager" "neo4j" {
  name             = "${var.goog_cm_deployment_name}-mig"
  base_instance_name = var.goog_cm_deployment_name
  zone             = var.zone
  target_size      = var.node_count

  version {
    instance_template = google_compute_instance_template.neo4j.id
  }

  named_port {
    name = "neo4j-bolt"
    port = 7687
  }

  named_port {
    name = "neo4j-http"
    port = 7474
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.neo4j.id
    initial_delay_sec = 300
  }
}

resource "google_compute_backend_service" "neo4j_http" {
  name             = "${var.goog_cm_deployment_name}-backend-http"
  protocol         = "HTTP"
  port_name        = "neo4j-http"
  timeout_sec      = 30
  load_balancing_scheme = "EXTERNAL"
  enable_cdn       = false

  backend {
    group          = google_compute_instance_group_manager.neo4j.instance_group
    balancing_mode = "RATE"
    max_rate_per_instance = 1000
  }

  health_checks = [google_compute_health_check.neo4j.id]
}

resource "google_compute_url_map" "neo4j_http" {
  name            = "${var.goog_cm_deployment_name}-url-map-http"
  default_service = google_compute_backend_service.neo4j_http.id
}

resource "google_compute_target_http_proxy" "neo4j" {
  name            = "${var.goog_cm_deployment_name}-http-proxy"
  url_map         = google_compute_url_map.neo4j_http.id
}

resource "google_compute_backend_service" "neo4j_bolt" {
  name             = "${var.goog_cm_deployment_name}-backend-bolt"
  protocol         = "TCP"
  port_name        = "neo4j-bolt"
  timeout_sec      = 30
  load_balancing_scheme = "EXTERNAL"

  backend {
    group          = google_compute_instance_group_manager.neo4j.instance_group
    balancing_mode = "CONNECTION"
    max_connections_per_instance = 1000
  }

  health_checks = [google_compute_health_check.neo4j.id]
}

resource "google_compute_global_address" "neo4j_http" {
  name = "${var.goog_cm_deployment_name}-http-ip"
}

resource "google_compute_global_forwarding_rule" "neo4j_http" {
  name                  = "${var.goog_cm_deployment_name}-forwarding-rule-http"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.neo4j.id
  ip_address            = google_compute_global_address.neo4j_http.id
}

resource "google_compute_address" "neo4j_bolt" {
  name         = "${var.goog_cm_deployment_name}-bolt-ip"
  region       = data.google_client_config.current.region
}

resource "google_compute_target_tcp_proxy" "neo4j_bolt" {
  name            = "${var.goog_cm_deployment_name}-tcp-proxy-bolt"
  backend_service = google_compute_backend_service.neo4j_bolt.id
}

resource "google_compute_forwarding_rule" "neo4j_bolt" {
  name                  = "${var.goog_cm_deployment_name}-forwarding-rule-bolt"
  region                = data.google_client_config.current.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "7687"
  target                = google_compute_target_tcp_proxy.neo4j_bolt.id
  ip_address            = google_compute_address.neo4j_bolt.id
}

data "google_client_config" "current" {}
