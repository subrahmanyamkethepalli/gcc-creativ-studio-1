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
# Frontend Cloud Build Trigger
#
# Firebase Hosting is NOT used.
#
# This module creates only the Cloud Build trigger for the frontend.
# frontend/cloudbuild-deploy.yaml is responsible for building the frontend
# container image and deploying cstudio-fe to Cloud Run.
# ==============================================================================

resource "google_cloudbuild_trigger" "this" {
  name            = "${var.service_name}-trigger"
  location        = var.gcp_region
  service_account = var.cloudbuild_sa_id
  filename        = var.cloudbuild_yaml_path
  substitutions   = var.build_substitutions

  repository_event_config {
    repository = var.source_repository_id

    push {
      branch = "^${var.github_branch_name}$"
    }
  }

  included_files = var.included_files_glob
}
