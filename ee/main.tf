provider "google" {
}

resource "google_compute_instance_template" "neo4j" {
  name = "${var.goog_cm_deployment_name}-instance-template"
  machine_type = var.machine_type

  disk {
    source_image = var.source_image
    disk_size_gb = var.disk_size
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    password   = "foobar123"
    nodeCount = var.node_count
  })
}

resource "google_compute_region_instance_group_manager" "neo4j" {
  name                      = "${var.goog_cm_deployment_name}-mig"
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

  auto_healing_policies {
    health_check      = google_compute_health_check.neo4j.id
    initial_delay_sec = 300
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

resource "google_compute_url_map" "neo4j_http" {
  name            = "${var.goog_cm_deployment_name}-url-map-http"
  default_service = google_compute_backend_service.neo4j_http.id
}

resource "google_compute_target_http_proxy" "neo4j" {
  name            = "${var.goog_cm_deployment_name}-http-proxy"
  url_map         = google_compute_url_map.neo4j_http.id
}

resource "google_compute_target_tcp_proxy" "neo4j_bolt" {
  name            = "${var.goog_cm_deployment_name}-tcp-proxy-bolt"
  backend_service = google_compute_backend_service.neo4j_bolt.id
}

resource "google_compute_global_address" "neo4j_http" {
  name = "${var.goog_cm_deployment_name}-http-ip"
}

resource "google_compute_address" "neo4j_bolt" {
  name         = "${var.goog_cm_deployment_name}-bolt-ip"
  region       = var.region
}

resource "google_compute_global_forwarding_rule" "neo4j_http" {
  name                  = "${var.goog_cm_deployment_name}-forwarding-rule-http"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "7474"
  target                = google_compute_target_http_proxy.neo4j.id
  ip_address            = google_compute_global_address.neo4j_http.id
}

resource "google_compute_forwarding_rule" "neo4j_bolt" {
  name                  = "${var.goog_cm_deployment_name}-forwarding-rule-bolt"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "7687"
  target                = google_compute_target_tcp_proxy.neo4j_bolt.id
  ip_address            = google_compute_address.neo4j_bolt.id
  region                = var.region
}


### Probably need a firewall rule for 7474 and 7687.
