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


# ============================================================
# Project Configuration
# ============================================================

variable "gcp_project_id" {
  type        = string
  description = "The GCP Project ID for the environment."
}

variable "gcp_region" {
  type        = string
  description = "The GCP region for the environment."
  default     = "us-central1"
}

variable "environment" {
  type        = string
  description = "The deployment environment, for example development or production."
}


# ============================================================
# Private Creative Studio URL
# ============================================================
/*
variable "internal_app_url" {
  type        = string
  description = "Private HTTPS URL exposed through the Internal Application Load Balancer."

  validation {
    condition = (
      can(regex("^https://", var.internal_app_url)) &&
      !endswith(var.internal_app_url, "/")
    )

    error_message = "internal_app_url must start with https:// and must not end with a slash."
  }
}

*/
# ============================================================
# Service Names
# ============================================================

variable "backend_service_name" {
  type        = string
  description = "Name of the backend Cloud Run service."
}

variable "frontend_service_name" {
  type        = string
  description = "Name of the frontend Cloud Run service."
}


# ============================================================
# Networking
# ============================================================

variable "vpc_id" {
  type        = string
  description = "Self-link or name of the existing VPC network."
}

variable "subnet_id" {
  type        = string
  description = "Self-link or name of the existing subnetwork."
}


# ============================================================
# Service Accounts
# ============================================================

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


# ============================================================
# GitHub / Cloud Build
# ============================================================

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
  description = "GitHub branch used by Cloud Build triggers."
}


# ============================================================
# Custom Audiences
# ============================================================

variable "backend_custom_audiences" {
  type        = list(string)
  description = "Custom audiences accepted by the backend Cloud Run service."
  default     = []
}

variable "frontend_custom_audiences" {
  type        = list(string)
  description = "Custom audiences accepted by the frontend Cloud Run service."
  default     = []
}


# ============================================================
# Backend Configuration
# ============================================================

variable "be_env_vars" {
  type        = map(map(string))
  description = "Common and environment-specific backend environment variables."
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

variable "backend_runtime_secrets" {
  type        = map(string)
  description = "Secret Manager secrets mounted into the backend Cloud Run service."
  default     = {}
}

variable "backend_secrets" {
  type        = list(string)
  description = "Secret names required by the backend."
  default     = []
}


# ============================================================
# Frontend Configuration
# ============================================================

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
  description = "Secret names required by the frontend."
  default     = []
}

variable "proxy_only_subnet_cidr" {
  type        = string
  description = "CIDR range for the Internal Application Load Balancer proxy-only subnet."
}

variable "ssl_certificate_id" {
  type        = string
  description = "Existing regional SSL certificate ID."
}

# ============================================================
# Google Cloud APIs
# ============================================================

variable "apis_to_enable" {
  type        = list(string)
  description = "Google Cloud APIs that Terraform should enable."

  default = [
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "iamcredentials.googleapis.com",
    "aiplatform.googleapis.com",
    "firestore.googleapis.com",
    "texttospeech.googleapis.com",
    "workflows.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
  ]
}
``