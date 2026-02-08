provider "google" {
  project = var.project_id
}

resource "google_service_account" "neo4j" {
  account_id   = "neo4j-service-account"
  display_name = "Neo4j Service Account"
}

data "google_iam_policy" "neo4j" {
  binding {
    role = "roles/compute.instanceAdmin"
    members = [
      "serviceAccount:${google_service_account.neo4j.email}"
    ]
  }
}
resource "google_compute_instance_template" "neo4j" {
  name         = "${var.goog_cm_deployment_name}-instance-template"
  machine_type = var.machine_type

  disk {
    source_image = var.source_image
    disk_size_gb = var.disk_size
    disk_type    = "hyperdisk-balanced"
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    password                = var.password
    nodeCount               = var.node_count
    goog_cm_deployment_name = var.goog_cm_deployment_name
  })

   service_account {
    email  = google_service_account.neo4j.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "neo4j" {
  name                      = "${var.goog_cm_deployment_name}-instance-group-manager"
  region                    = var.region
  distribution_policy_zones = var.zones
  target_size               = var.node_count
  base_instance_name        = var.goog_cm_deployment_name

  version {
    instance_template = google_compute_instance_template.neo4j.id
  }

  named_port {
    name = "neo4j-http"
    port = 7474
  }

  named_port {
    name = "neo4j-bolt"
    port = 7687
  }
}

resource "google_compute_health_check" "neo4j" {
  name = "${var.goog_cm_deployment_name}-health-check"

  timeout_sec        = 1
  check_interval_sec = 300

  tcp_health_check {
    port = "7474"
  }
}

resource "google_compute_backend_service" "neo4j_http" {
  name                  = "${var.goog_cm_deployment_name}-backend-http"
  protocol              = "TCP"
  port_name             = "neo4j-http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"
  enable_cdn            = false

  backend {
    group                        = google_compute_region_instance_group_manager.neo4j.instance_group
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 1000
  }

  health_checks = [google_compute_health_check.neo4j.id]
}

resource "google_compute_backend_service" "neo4j_bolt" {
  name                  = "${var.goog_cm_deployment_name}-backend-bolt"
  protocol              = "TCP"
  port_name             = "neo4j-bolt"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"

  backend {
    group                        = google_compute_region_instance_group_manager.neo4j.instance_group
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 1000
  }

  health_checks = [google_compute_health_check.neo4j.id]
}

resource "google_compute_target_tcp_proxy" "neo4j_http" {
  name            = "${var.goog_cm_deployment_name}-tcp-proxy-http"
  backend_service = google_compute_backend_service.neo4j_http.id
}

resource "google_compute_target_tcp_proxy" "neo4j_bolt" {
  name            = "${var.goog_cm_deployment_name}-tcp-proxy-bolt"
  backend_service = google_compute_backend_service.neo4j_bolt.id
}

resource "google_compute_global_forwarding_rule" "neo4j_http" {
  name                  = "${var.goog_cm_deployment_name}-forwarding-rule-http"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "7474"
  target                = google_compute_target_tcp_proxy.neo4j_http.id
  ip_address            = google_compute_global_address.neo4j.id
}

resource "google_compute_global_forwarding_rule" "neo4j_bolt" {
  name                  = "${var.goog_cm_deployment_name}-forwarding-rule-bolt"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "7687"
  target                = google_compute_target_tcp_proxy.neo4j_bolt.id
  ip_address            = google_compute_global_address.neo4j.id
}

resource "google_compute_global_address" "neo4j" {
  name = "${var.goog_cm_deployment_name}"
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
