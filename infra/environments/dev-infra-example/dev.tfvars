gcp_project_id = "sbd-ai-poc-h"
gcp_region     = "us-central1"
environment    = "development"

# ============================================================
# Private Creative Studio URL
# ============================================================
# Replace this with the actual private DNS name pointing to the
# Internal Application Load Balancer.
#internal_app_url = "https://YOUR_INTERNAL_DNS_NAME"


# ============================================================
# Service Names
# ============================================================

backend_service_name  = "cstudio-be"
frontend_service_name = "cstudio-fe"


# ============================================================
# GitHub Repository
# ============================================================

github_conn_name   = "gh-repo-owner-con"
github_repo_owner  = "RepoOwnerName"
github_repo_name   = "repo-owner-gcc-creative-studio"
github_branch_name = "develop"


#proxy_only_subnet_cidr = "YOUR_UNUSED_PROXY_ONLY_CIDR"
#ssl_certificate_id = "YOUR_REGIONAL_SSL_CERTIFICATE_ID"

# ============================================================
# Custom Audiences
# ============================================================

backend_custom_audiences = [
  "YOUR_OAUTH_WEB_CLIENT_ID_HERE",
  "YOUR_GCP_PROJECT_ID"
]

frontend_custom_audiences = [
  "YOUR_OAUTH_WEB_CLIENT_ID_HERE",
  "YOUR_GCP_PROJECT_ID"
]


# ============================================================
# Backend Environment Variables
# ============================================================

be_env_vars = {
  common = {
    LOG_LEVEL = "INFO"
  }

  development = {
    ENVIRONMENT                    = "development"
    GOOGLE_TOKEN_AUDIENCE          = "YOUR_OAUTH_WEB_CLIENT_ID_HERE"
    IDENTITY_PLATFORM_ALLOWED_ORGS = ""
  }

  production = {
    ENVIRONMENT                    = "production"
    GOOGLE_TOKEN_AUDIENCE          = "YOUR_OAUTH_WEB_CLIENT_ID_HERE"
    IDENTITY_PLATFORM_ALLOWED_ORGS = ""
  }
}


# ============================================================
# Frontend Build
# ============================================================

fe_build_substitutions = {
  _ANGULAR_BUILD_COMMAND = "build-dev"
}


# ============================================================
# Frontend Secrets
#
# These are Firebase Web SDK / Authentication settings.
# Firebase Hosting is NOT used.
# ============================================================

frontend_secrets = [
  "FIREBASE_API_KEY",
  "FIREBASE_AUTH_DOMAIN",
  "FIREBASE_PROJECT_ID",
  "FIREBASE_STORAGE_BUCKET",
  "FIREBASE_MESSAGING_SENDER_ID",
  "FIREBASE_APP_ID",
  "FIREBASE_MEASUREMENT_ID",
  "GOOGLE_CLIENT_ID",
]


# ============================================================
# Backend Secrets
# ============================================================

backend_secrets = [
  "GOOGLE_TOKEN_AUDIENCE",
]

backend_runtime_secrets = {
  GOOGLE_TOKEN_AUDIENCE = "GOOGLE_TOKEN_AUDIENCE"
}


# ============================================================
# Google Cloud APIs
# ============================================================

apis_to_enable = [
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
]