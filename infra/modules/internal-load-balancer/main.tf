/*
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# ==============================================================================
# Creative Studio Regional Internal HTTPS Application Load Balancer
#
# Routing:
#
#   /*       -> cstudio-fe
#   /api/*   -> cstudio-be
#
# Cloud Run services are connected through regional serverless NEGs.
# ==============================================================================


# ------------------------------------------------------------------------------
# Proxy-only subnet
#
# Regional Internal Application Load Balancer requires a proxy-only subnet.
#
# IMPORTANT:
# The CIDR range must not overlap with existing VPC/subnet ranges.
# ------------------------------------------------------------------------------

resource "google_compute_subnetwork" "proxy_only" {
  project = var.gcp_project_id

  name          = "${var.lb_name}-proxy-only"
  region        = var.gcp_region
  network       = var.vpc_id
  ip_cidr_range = var.proxy_only_subnet_cidr

  purpose = "REGIONAL_MANAGED_PROXY"
  role    = "ACTIVE"
}


# ------------------------------------------------------------------------------
# Frontend Cloud Run Serverless NEG
# ------------------------------------------------------------------------------

resource "google_compute_region_network_endpoint_group" "frontend" {
  project = var.gcp_project_id

  name   = "${var.frontend_service_name}-neg"
  region = var.gcp_region

  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.frontend_service_name
  }
}


# ------------------------------------------------------------------------------
# Backend Cloud Run Serverless NEG
# ------------------------------------------------------------------------------

resource "google_compute_region_network_endpoint_group" "backend" {
  project = var.gcp_project_id

  name   = "${var.backend_service_name}-neg"
  region = var.gcp_region

  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.backend_service_name
  }
}


# ------------------------------------------------------------------------------
# Frontend Backend Service
# ------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "frontend" {
  project = var.gcp_project_id

  name   = "${var.frontend_service_name}-backend"
  region = var.gcp_region

  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.frontend.id
  }
}


# ------------------------------------------------------------------------------
# Backend Backend Service
# ------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "backend" {
  project = var.gcp_project_id

  name   = "${var.backend_service_name}-backend"
  region = var.gcp_region

  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.backend.id
  }
}


# ------------------------------------------------------------------------------
# URL Map
#
# Default:
#
#   /* -> frontend
#
# API:
#
#   /api
#   /api/*
#
#       -> backend
# ------------------------------------------------------------------------------

resource "google_compute_region_url_map" "this" {
  project = var.gcp_project_id

  name   = "${var.lb_name}-url-map"
  region = var.gcp_region

  default_service = google_compute_region_backend_service.frontend.id

  host_rule {
    hosts = ["*"]

    path_matcher = "creative-studio"
  }

  path_matcher {
    name = "creative-studio"

    default_service = google_compute_region_backend_service.frontend.id

    path_rule {
      paths = [
        "/api",
        "/api/*"
      ]

      service = google_compute_region_backend_service.backend.id
    }
  }
}


# ------------------------------------------------------------------------------
# Internal Load Balancer IP
# ------------------------------------------------------------------------------

resource "google_compute_address" "this" {
  project = var.gcp_project_id

  name         = "${var.lb_name}-ip"
  region       = var.gcp_region
  address_type = "INTERNAL"

  subnetwork = var.lb_subnet_id
}


# ------------------------------------------------------------------------------
# HTTPS Proxy
#
# An existing regional SSL certificate is supplied to this module.
#
# Do not store certificate private keys directly in this module.
# ------------------------------------------------------------------------------

resource "google_compute_region_target_https_proxy" "this" {
  project = var.gcp_project_id

  name   = "${var.lb_name}-https-proxy"
  region = var.gcp_region

  url_map = google_compute_region_url_map.this.id

  ssl_certificates = [
    var.ssl_certificate_id
  ]
}


# ------------------------------------------------------------------------------
# Internal HTTPS Forwarding Rule
# ------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "https" {
  project = var.gcp_project_id

  name   = "${var.lb_name}-https-forwarding-rule"
  region = var.gcp_region

  load_balancing_scheme = "INTERNAL_MANAGED"

  network    = var.vpc_id
  subnetwork = var.lb_subnet_id

  ip_address = google_compute_address.this.id

  ip_protocol = "TCP"
  port_range  = "443"

  target = google_compute_region_target_https_proxy.this.id

  depends_on = [
    google_compute_subnetwork.proxy_only
  ]
}

*/