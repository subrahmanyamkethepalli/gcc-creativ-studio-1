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
# Shared Platform Resources
# ==============================================================================

resource "google_storage_bucket" "genmedia" {
  name                        = "${var.gcp_project_id}-cs-${var.environment}-bucket"
  location                    = var.gcp_region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  cors {
    origin = [
      var.internal_app_url
    ]

    method = [
      "GET",
      "PUT",
      "POST",
      "DELETE",
      "HEAD",
      "OPTIONS"
    ]

    response_header = [
      "Content-Type",
      "Access-Control-Allow-Origin",
      "x-goog-resumable",
      "Authorization",
      "Origin"
    ]

    max_age_seconds = 3600
  }
}


# ==============================================================================
# Project Information
# ==============================================================================

data "google_project" "project" {
  project_id = var.gcp_project_id
}


# ==============================================================================
# Private Application URLs and Backend Environment Variables
# ==============================================================================

locals {
  region_code = join(
    "",
    [
      for segment in split("-", var.gcp_region) :
      substr(segment, 0, 1)
    ]
  )

  # Private Creative Studio application URL exposed by the
  # Internal Application Load Balancer.
  frontend_url = trimsuffix(var.internal_app_url, "/")

  # Backend API is exposed through the same Internal Application Load Balancer.
  backend_url = "${local.frontend_url}/api"

  backend_env_vars = merge(
    lookup(var.be_env_vars, "common", {}),
    lookup(var.be_env_vars, var.environment, {}),
    {
      CORS_ORIGINS           = jsonencode([local.frontend_url])
      GENMEDIA_BUCKET        = google_storage_bucket.genmedia.name
      BACKEND_URL            = local.backend_url
      WORKFLOWS_EXECUTOR_URL = "${local.backend_url}/workflows-executor"
    }
  )
}


# ==============================================================================
# Cloud Build Repository Connection
# ==============================================================================

resource "google_cloudbuildv2_repository" "source_repo" {
  provider = google-beta

  name              = var.github_repo_name
  location          = var.gcp_region
  parent_connection = "projects/${var.gcp_project_id}/locations/${var.gcp_region}/connections/${var.github_conn_name}"
  remote_uri        = "https://github.com/${var.github_repo_owner}/${var.github_repo_name}.git"
}


# ==============================================================================
# Database Password
# ==============================================================================

data "google_secret_manager_secret_version" "db_password" {
  secret  = "creative-studio-db-password"
  project = var.gcp_project_id
  version = "latest"
}


# ==============================================================================
# PostgreSQL
# ==============================================================================

module "postgresql" {
  source = "../postgresql"

  project_id = var.gcp_project_id
  region     = var.gcp_region
  vpc_id     = var.vpc_id

  db_password = data.google_secret_manager_secret_version.db_password.secret_data
}


# ==============================================================================
# Backend Cloud Run Service
# ==============================================================================

module "backend_service" {
  source = "../cloud-run-service"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  environment    = var.environment

  service_name    = var.backend_service_name
  resource_prefix = "cs-be"

  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  cloud_run_sa     = var.cloud_run_sa
  cloudbuild_sa    = var.cloudbuild_sa
  cloudbuild_sa_id = var.cloudbuild_sa_id

  github_conn_name   = var.github_conn_name
  github_repo_owner  = var.github_repo_owner
  github_repo_name   = var.github_repo_name
  github_branch_name = var.github_branch_name

  source_repository_id = google_cloudbuildv2_repository.source_repo.id

  cloudbuild_yaml_path = "backend/cloudbuild.yaml"
  included_files_glob  = ["backend/**"]

  container_env_vars = local.backend_env_vars
  runtime_secrets    = var.backend_runtime_secrets
  custom_audiences   = var.backend_custom_audiences

  scaling_min_instances = 1
  scaling_max_instances = var.backend_scaling_max_instances

  cpu    = var.be_cpu
  memory = var.be_memory

  build_substitutions = merge(
    var.be_build_substitutions,
    {
      _REGION       = var.gcp_region
      _SERVICE_NAME = var.backend_service_name
    }
  )

  cloud_sql_connection_name = module.postgresql.connection_name
  db_name                   = module.postgresql.db_name
  db_user                   = module.postgresql.db_user
  db_secret_id              = "creative-studio-db-password"
}

/*
# ==============================================================================
# Firebase Project
#
# Firebase Hosting is not used.
# The Firebase project is retained because Creative Studio still uses the
# Firebase Web App SDK and Firebase Authentication configuration.
# ==============================================================================

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.gcp_project_id
}


# ==============================================================================
# Frontend Build Trigger
#
# This module now creates only the frontend Cloud Build trigger.
# It must not create a Firebase Hosting site.
#
# The referenced frontend/cloudbuild-deploy.yaml must build the frontend
# Docker image and deploy cstudio-fe to Cloud Run.
# ==============================================================================

module "frontend_service" {
  source = "../firebase-hosting-service"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region

  service_name    = var.frontend_service_name
  environment     = var.environment
  resource_prefix = "cs-fe"

  cloudbuild_sa    = var.cloudbuild_sa
  cloudbuild_sa_id = var.cloudbuild_sa_id

  source_repository_id = google_cloudbuildv2_repository.source_repo.id

  github_branch_name   = var.github_branch_name
  cloudbuild_yaml_path = "frontend/cloudbuild-deploy.yaml"
  included_files_glob  = ["frontend/**"]

  build_substitutions = merge(
    var.fe_build_substitutions,
    {
      _BACKEND_URL        = "/api"
      _FE_SERVICE_NAME    = var.frontend_service_name
      _BACKEND_SERVICE_ID = var.backend_service_name
      _PROJECT_ID         = var.gcp_project_id
      _REGION             = var.gcp_region
    }
  )

  depends_on = [
    google_firebase_project.default
  ]
}

*/
# ==============================================================================
# Secret Manager
# ==============================================================================

module "frontend_secrets" {
  source = "../secret-manager"

  gcp_project_id = var.gcp_project_id
  secret_names   = var.frontend_secrets
}

module "backend_secrets" {
  source = "../secret-manager"

  gcp_project_id = var.gcp_project_id
  secret_names   = var.backend_secrets
}

# ==============================================================================
# Internal Application Load Balancer
# ==============================================================================
/*
module "internal_load_balancer" {
  source = "../internal-load-balancer"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region

  lb_name = "cs-studio-lb"

  vpc_id       = var.vpc_id
  lb_subnet_id = var.subnet_id

  proxy_only_subnet_cidr = var.proxy_only_subnet_cidr

  frontend_service_name = var.frontend_service_name
  backend_service_name  = var.backend_service_name

  ssl_certificate_id = var.ssl_certificate_id
}
*/
