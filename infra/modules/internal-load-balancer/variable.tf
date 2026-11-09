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
# Project
# ==============================================================================

variable "gcp_project_id" {
  type        = string
  description = "Google Cloud project ID."
}

variable "gcp_region" {
  type        = string
  description = "Region containing Cloud Run and the Internal Application Load Balancer."
}


# ==============================================================================
# Load Balancer
# ==============================================================================

variable "lb_name" {
  type        = string
  description = "Name of the Internal Application Load Balancer."
  default     = "cs-studio-lb"
}


# ==============================================================================
# Network
# ==============================================================================

variable "vpc_id" {
  type        = string
  description = "VPC network self-link or ID."
}

variable "lb_subnet_id" {
  type        = string
  description = "Regular subnet used by the Internal Application Load Balancer forwarding rule."
}


# ==============================================================================
# Proxy-only Subnet
#
# IMPORTANT:
# Pick an unused CIDR from the VPC.
#
# Example only:
#   10.129.0.0/23
#
# Do NOT use the example until you verify it does not overlap.
# ==============================================================================

variable "proxy_only_subnet_cidr" {
  type        = string
  description = "CIDR range for the REGIONAL_MANAGED_PROXY proxy-only subnet."
}


# ==============================================================================
# Cloud Run
# ==============================================================================

variable "frontend_service_name" {
  type        = string
  description = "Frontend Cloud Run service name."
}

variable "backend_service_name" {
  type        = string
  description = "Backend Cloud Run service name."
}


# ==============================================================================
# HTTPS Certificate
# ==============================================================================

variable "ssl_certificate_id" {
  type        = string
  description = "Self-link/ID of the existing regional SSL certificate used by the Internal HTTPS Application Load Balancer."
}

*/