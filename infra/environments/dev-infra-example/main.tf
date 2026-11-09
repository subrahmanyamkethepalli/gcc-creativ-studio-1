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

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }

    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}


# ============================================================
# Google Providers
# ============================================================

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}


# ============================================================
# Enable Required Google Cloud APIs
# ============================================================

resource "google_project_service" "apis" {
  for_each = toset(var.apis_to_enable)

  project = var.gcp_project_id
  service = each.key

  disable_on_destroy = false
}


# ============================================================
# Creative Studio Platform
# ============================================================

module "creative_studio_platform" {
  source = "../../modules/platform"

  # ----------------------------------------------------------
  # Project
  # ----------------------------------------------------------

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  environment    = var.environment


  # ----------------------------------------------------------
  # Private Application URL
  #
  # This replaces Firebase Hosting *.web.app URL.
  # ----------------------------------------------------------

  #internal_app_url = var.internal_app_url

  #proxy_only_subnet_cidr = var.proxy_only_subnet_cidr
  #ssl_certificate_id     = var.ssl_certificate_id
  
  # ----------------------------------------------------------
  # Networking
  # ----------------------------------------------------------

  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id


  # ----------------------------------------------------------
  # Service Accounts
  # ----------------------------------------------------------

  cloud_run_sa     = var.cloud_run_sa
  cloudbuild_sa    = var.cloudbuild_sa
  cloudbuild_sa_id = var.cloudbuild_sa_id


  # ----------------------------------------------------------
  # Backend Cloud Run
  # ----------------------------------------------------------

  backend_service_name     = var.backend_service_name
  backend_custom_audiences = var.backend_custom_audiences

  be_env_vars             = var.be_env_vars
  be_build_substitutions  = var.be_build_substitutions
  backend_runtime_secrets = var.backend_runtime_secrets

  be_cpu    = var.be_cpu
  be_memory = var.be_memory


  # ----------------------------------------------------------
  # Frontend Cloud Run
  # ----------------------------------------------------------

  frontend_service_name     = var.frontend_service_name
  frontend_custom_audiences = var.frontend_custom_audiences

  fe_build_substitutions = var.fe_build_substitutions

  fe_cpu    = var.fe_cpu
  fe_memory = var.fe_memory


  # ----------------------------------------------------------
  # GitHub / Cloud Build
  # ----------------------------------------------------------

  github_conn_name   = var.github_conn_name
  github_repo_owner  = var.github_repo_owner
  github_repo_name   = var.github_repo_name
  github_branch_name = var.github_branch_name


  # ----------------------------------------------------------
  # Secret Manager
  # ----------------------------------------------------------

  frontend_secrets = var.frontend_secrets
  backend_secrets  = var.backend_secrets


  # ----------------------------------------------------------
  # Dependencies
  # ----------------------------------------------------------

  depends_on = [
    google_project_service.apis
  ]
}