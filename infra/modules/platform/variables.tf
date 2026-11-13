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
# Common Platform Variables
# ==============================================================================

variable "gcp_project_id" {
  type        = string
  description = "Google Cloud project ID."
}

variable "gcp_region" {
  type        = string
  description = "Google Cloud region used for the deployment."
}

variable "environment" {
  type        = string
  description = "Deployment environment, for example development or production."
}


# ==============================================================================
# Private Application URL
# ==============================================================================


variable "internal_app_url" {
  type        = string
  description = "Private HTTPS URL exposed through the Internal Application Load Balancer."
  default     = ""

  validation {
    condition = (
      var.internal_app_url == "" ||
      (
        can(regex("^https://", var.internal_app_url)) &&
        !endswith(var.internal_app_url, "/")
      )
    )

    error_message = "internal_app_url must be empty or start with https:// and must not end with a slash."
  }
}
# ==============================================================================
# Backend Variables
# ==============================================================================

variable "backend_service_name" {
  type        = string
  description = "Name of the backend Cloud Run service."
}

variable "backend_custom_audiences" {
  type        = list(string)
  description = "Custom audiences accepted by the backend Cloud Run service."
  default     = []
}

variable "be_env_vars" {
  type        = map(map(string))
  description = "Backend environment variables grouped by common and environment-specific values."
  default     = {}
}

variable "be_build_substitutions" {
  type        = map(string)
  description = "Substitution variables for the backend Cloud Build trigger."
  default     = {}
}

variable "be_cpu" {
  type        = string
  description = "CPU limit for the backend Cloud Run service."
  default     = "2000m"
}

variable "be_memory" {
  type        = string
  description = "Memory limit for the backend Cloud Run service."
  default     = "2048Mi"
}

variable "backend_scaling_max_instances" {
  type        = number
  description = "Maximum number of backend Cloud Run instances."
  default     = 100
}

variable "backend_runtime_secrets" {
  type        = map(string)
  description = "Secret Manager secrets mounted as backend runtime environment variables."
  default     = {}
}

variable "backend_secrets" {
  type        = list(string)
  description = "Secret Manager secret names required by the backend application."
  default     = []
}


# ==============================================================================
# Frontend Variables
# ==============================================================================

variable "frontend_service_name" {
  type        = string
  description = "Name of the frontend Cloud Run service."
}

variable "frontend_custom_audiences" {
  type        = list(string)
  description = "Custom audiences accepted by the frontend Cloud Run service."
  default     = []
}

variable "fe_build_substitutions" {
  type        = map(string)
  description = "Substitution variables for the frontend Cloud Build trigger."
  default     = {}
}

variable "fe_cpu" {
  type        = string
  description = "CPU limit for the frontend Cloud Run service."
  default     = "1000m"
}

variable "fe_memory" {
  type        = string
  description = "Memory limit for the frontend Cloud Run service."
  default     = "512Mi"
}

variable "frontend_secrets" {
  type        = list(string)
  description = "Secret Manager secret names required during the frontend build."
  default     = []
}


# ==============================================================================
# GitHub and Cloud Build Variables
# ==============================================================================

variable "github_conn_name" {
  type        = string
  description = "Name of the Cloud Build GitHub connection."
}

variable "github_repo_owner" {
  type        = string
  description = "Owner of the GitHub repository."
}

variable "github_repo_name" {
  type        = string
  description = "Name of the GitHub repository."
}

variable "github_branch_name" {
  type        = string
  description = "GitHub branch used by the Cloud Build triggers."
}


# ==============================================================================
# Networking
# ==============================================================================

variable "vpc_id" {
  type        = string
  description = "Self-link or name of the existing VPC network."
}

variable "subnet_id" {
  type        = string
  description = "Self-link or name of the existing subnetwork."
}
variable "container_env_vars" {
 description = "Environment variables for backend Cloud Run"
 type        = map(string)
 default     = {}
}

# ==============================================================================
# Service Accounts
# ==============================================================================

variable "cloud_run_sa" {
  type        = string
  description = "Cloud Run runtime service account email."
}

variable "cloudbuild_sa" {
  type        = string
  description = "Cloud Build trigger service account email."
}

variable "cloudbuild_sa_id" {
  type        = string
  description = "Cloud Build trigger service account resource ID."
}

variable "proxy_only_subnet_cidr" {
  type        = string
  description = "Unused VPC CIDR range for the Internal Application Load Balancer proxy-only subnet."
  default     = ""
}

variable "ssl_certificate_id" {
  type        = string
  description = "Existing regional SSL certificate ID for the Internal HTTPS Application Load Balancer."
  default     = ""
}
