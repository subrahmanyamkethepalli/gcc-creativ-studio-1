#!/bin/bash
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
# Creative Studio Secret Manager Update Script
#
# Updates Google Secret Manager values using:
#   - Terraform outputs
#   - Firebase Web App SDK configuration
#   - Firebase Management API
#   - Manual input when automatic discovery is not possible
#
# Firebase Hosting is NOT used.
# Firebase Web App / Authentication configuration is retained.
#
# Usage:
#   cd infra/environments/dev-infra
#   ../../update_secrets.sh
# ==============================================================================

set -e
set -o pipefail


# ==============================================================================
# Colors
# ==============================================================================

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'


# ==============================================================================
# Helper Functions
# ==============================================================================

info() {
  echo -e "${C_CYAN}> $1${C_RESET}"
}

success() {
  echo -e "${C_GREEN}✅  $1${C_RESET}"
}

warn() {
  echo -e "${C_YELLOW}⚠️  $1${C_RESET}"
}

fail() {
  echo -e "${C_RED}❌  $1${C_RESET}" >&2
  exit 1
}


# ==============================================================================
# Dependency Checks
# ==============================================================================

info "Checking required tools..."

command -v gcloud >/dev/null ||
  fail "gcloud CLI not found."

command -v jq >/dev/null ||
  fail "jq is not installed."

command -v terraform >/dev/null ||
  fail "Terraform is not installed."

command -v firebase >/dev/null ||
  fail "Firebase CLI not found. Install it with: npm install -g firebase-tools"

command -v curl >/dev/null ||
  fail "curl is not installed."

success "Required tools found: gcloud, jq, terraform, firebase, curl"


# ==============================================================================
# Find Terraform Variables File
# ==============================================================================

TFVARS_FILE=$(
  find . \
    -maxdepth 1 \
    -name "*.tfvars" \
    ! -name "terraform.tfvars.dist" |
    head -n 1
)

if [ -z "$TFVARS_FILE" ]; then
  fail "No .tfvars file found in the current directory."
fi

info "Using variables from: ${C_YELLOW}${TFVARS_FILE}${C_RESET}"


# ==============================================================================
# Read Terraform Outputs
# ==============================================================================

info "Fetching Terraform outputs..."

TERRAFORM_OUTPUTS=$(terraform output -json)

PROJECT_ID=$(
  echo "$TERRAFORM_OUTPUTS" |
    jq -r 'try (.gcp_project_id.value // "") catch ""'
)

FRONTEND_SECRETS=$(
  echo "$TERRAFORM_OUTPUTS" |
    jq -r 'try (.frontend_secrets.value[]?) catch ""'
)

BACKEND_SECRETS=$(
  echo "$TERRAFORM_OUTPUTS" |
    jq -r 'try (.backend_secrets.value[]?) catch ""'
)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  fail "Could not find gcp_project_id in Terraform outputs. Run terraform apply first."
fi


# ==============================================================================
# Combine Secret Lists
# ==============================================================================

ALL_SECRETS=$(
  printf "%s\n%s\n" \
    "$FRONTEND_SECRETS" \
    "$BACKEND_SECRETS" |
    sed '/^[[:space:]]*$/d' |
    sort -u
)

if [ -z "$ALL_SECRETS" ]; then
  success "No frontend or backend secrets need to be updated."
  exit 0
fi

info "Project: ${C_YELLOW}${PROJECT_ID}${C_RESET}"

warn "The following secrets will be processed:"

echo -e "${C_YELLOW}${ALL_SECRETS}${C_RESET}"


# ==============================================================================
# Confirmation
# ==============================================================================

read -r -p "Continue? (y/n): " REPLY
echo

if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  fail "Operation cancelled."
fi


# ==============================================================================
# Initialize Auto-discovered Values
# ==============================================================================

AUTO_FIREBASE_API_KEY=""
AUTO_FIREBASE_AUTH_DOMAIN=""
AUTO_FIREBASE_STORAGE_BUCKET=""
AUTO_FIREBASE_MESSAGING_SENDER_ID=""
AUTO_FIREBASE_APP_ID=""
AUTO_FIREBASE_MEASUREMENT_ID=""
AUTO_OAUTH_CLIENT_ID=""


# ==============================================================================
# Discover Firebase Web App
#
# Firebase Hosting is NOT used.
#
# We identify the Firebase Web App by frontend_service_name.
# Expected value:
#   cstudio-fe
# ==============================================================================

info "Checking Firebase Web App configuration..."

FE_SERVICE_NAME=$(
  grep -E '^[[:space:]]*frontend_service_name[[:space:]]*=' \
    "$TFVARS_FILE" |
    head -n 1 |
    awk -F'"' '{print $2}' || true
)

if [ -z "$FE_SERVICE_NAME" ]; then
  FE_SERVICE_NAME="cstudio-fe"

  warn "frontend_service_name was not found in ${TFVARS_FILE}."
  warn "Falling back to: ${FE_SERVICE_NAME}"
fi

info "Looking for Firebase Web App: ${C_YELLOW}${FE_SERVICE_NAME}${C_RESET}"


# ==============================================================================
# Get Firebase Web App ID
# ==============================================================================

FIREBASE_APPS_JSON=$(
  firebase apps:list \
    --project="$PROJECT_ID" \
    --json \
    2>/dev/null || echo "{}"
)

WEB_APP_ID=$(
  echo "$FIREBASE_APPS_JSON" |
    jq -r \
      --arg name "$FE_SERVICE_NAME" \
      'try (.result[]? | select(.displayName == $name) | .appId) catch ""' |
    head -n 1
)


# ==============================================================================
# Retrieve Firebase SDK Configuration
# ==============================================================================

WEB_APP_SDK_CONFIG=""

if [ -n "$WEB_APP_ID" ] && [ "$WEB_APP_ID" != "null" ]; then

  success "Found Firebase Web App ID: ${WEB_APP_ID}"

  WEB_APP_CONFIG_RAW=$(
    firebase apps:sdkconfig WEB "$WEB_APP_ID" \
      --project="$PROJECT_ID" \
      --json \
      2>/dev/null || echo "{}"
  )

  WEB_APP_SDK_CONFIG=$(
    echo "$WEB_APP_CONFIG_RAW" |
      jq -c 'try (.result.sdkConfig // empty) catch empty'
  )

else

  warn "Firebase Web App '${FE_SERVICE_NAME}' was not found."

fi


# ==============================================================================
# Extract Firebase Web SDK Configuration
# ==============================================================================

if [ -n "$WEB_APP_SDK_CONFIG" ]; then

  success "Found Firebase Web App configuration."

  AUTO_FIREBASE_API_KEY=$(
    echo "$WEB_APP_SDK_CONFIG" |
      jq -r '.apiKey // ""'
  )

  AUTO_FIREBASE_AUTH_DOMAIN=$(
    echo "$WEB_APP_SDK_CONFIG" |
      jq -r '.authDomain // ""'
  )

  AUTO_FIREBASE_STORAGE_BUCKET=$(
    echo "$WEB_APP_SDK_CONFIG" |
      jq -r '.storageBucket // ""'
  )

  AUTO_FIREBASE_MESSAGING_SENDER_ID=$(
    echo "$WEB_APP_SDK_CONFIG" |
      jq -r '.messagingSenderId // ""'
  )

  AUTO_FIREBASE_APP_ID=$(
    echo "$WEB_APP_SDK_CONFIG" |
      jq -r '.appId // ""'
  )

  AUTO_FIREBASE_MEASUREMENT_ID=$(
    echo "$WEB_APP_SDK_CONFIG" |
      jq -r '.measurementId // ""'
  )

else

  warn "Could not retrieve Firebase Web App SDK configuration."
  warn "Missing Firebase/Auth values will require manual input."

fi


# ==============================================================================
# Discover OAuth Client ID
#
# Firebase apps:sdkconfig does not reliably provide the OAuth Client ID.
# Try the Firebase Management API.
# ==============================================================================

if [ -n "$WEB_APP_ID" ] && [ "$WEB_APP_ID" != "null" ]; then

  info "Attempting to discover OAuth Client ID..."

  AUTH_TOKEN=$(
    gcloud auth print-access-token 2>/dev/null || echo ""
  )

  if [ -n "$AUTH_TOKEN" ]; then

    OAUTH_CONFIG=$(
      curl -s \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/webApps/${WEB_APP_ID}/config" ||
        echo "{}"
    )

    AUTO_OAUTH_CLIENT_ID=$(
      echo "$OAUTH_CONFIG" |
        jq -r 'try (.oauthClientId // "") catch ""'
    )

  fi

fi


if [ -n "$AUTO_OAUTH_CLIENT_ID" ] &&
   [ "$AUTO_OAUTH_CLIENT_ID" != "null" ]; then

  success "OAuth Client ID discovered automatically."

else

  AUTO_OAUTH_CLIENT_ID=""
  warn "OAuth Client ID could not be discovered automatically."

fi


# ==============================================================================
# Process Each Secret
# ==============================================================================

for SECRET_NAME in $ALL_SECRETS; do

  info "Processing secret: ${C_YELLOW}${SECRET_NAME}${C_RESET}"

  SECRET_VALUE=""
  AUTO_DISCOVERED=false


  # ---------------------------------------------------------------------------
  # Map Secret Names to Auto-discovered Values
  # ---------------------------------------------------------------------------

  case "$SECRET_NAME" in

    "FIREBASE_API_KEY")
      SECRET_VALUE="$AUTO_FIREBASE_API_KEY"
      AUTO_DISCOVERED=true
      ;;

    "FIREBASE_AUTH_DOMAIN")
      SECRET_VALUE="$AUTO_FIREBASE_AUTH_DOMAIN"
      AUTO_DISCOVERED=true
      ;;

    "FIREBASE_PROJECT_ID")
      SECRET_VALUE="$PROJECT_ID"
      AUTO_DISCOVERED=true
      ;;

    "FIREBASE_STORAGE_BUCKET")
      SECRET_VALUE="$AUTO_FIREBASE_STORAGE_BUCKET"
      AUTO_DISCOVERED=true
      ;;

    "FIREBASE_MESSAGING_SENDER_ID")
      SECRET_VALUE="$AUTO_FIREBASE_MESSAGING_SENDER_ID"
      AUTO_DISCOVERED=true
      ;;

    "FIREBASE_APP_ID")
      SECRET_VALUE="$AUTO_FIREBASE_APP_ID"
      AUTO_DISCOVERED=true
      ;;

    "FIREBASE_MEASUREMENT_ID")
      SECRET_VALUE="$AUTO_FIREBASE_MEASUREMENT_ID"
      AUTO_DISCOVERED=true
      ;;

    "GOOGLE_CLIENT_ID")
      SECRET_VALUE="$AUTO_OAUTH_CLIENT_ID"
      AUTO_DISCOVERED=true
      ;;

    
  esac


  # ---------------------------------------------------------------------------
  # Manual Input if Automatic Discovery Failed
  # ---------------------------------------------------------------------------

  if [ "$AUTO_DISCOVERED" = true ] &&
     [ -n "$SECRET_VALUE" ] &&
     [ "$SECRET_VALUE" != "null" ]; then

    info "  Auto-discovered value."

  elif [ "$SECRET_NAME" = "GOOGLE_CLIENT_ID" ] ||
       [ "$SECRET_NAME" = "GOOGLE_TOKEN_AUDIENCE" ]; then

    warn "  OAuth Client ID could not be auto-discovered."

    echo
    echo "  Open:"
    echo "  https://console.cloud.google.com/apis/credentials?project=${PROJECT_ID}"
    echo
    echo "  Find the OAuth 2.0 Client ID of type 'Web application'."
    echo

    read -r -s -p "  Enter OAuth Client ID: " SECRET_VALUE
    echo

  else

    warn "  Automatic value discovery was not available."

    echo -e \
      "${C_CYAN}  Enter the required value. Input will not be displayed.${C_RESET}"

    read -r -s -p "  Enter new value: " SECRET_VALUE
    echo

  fi


  # ---------------------------------------------------------------------------
  # Handle Empty Values
  # ---------------------------------------------------------------------------

  if [ -z "$SECRET_VALUE" ]; then

    if [ "$SECRET_NAME" = "FIREBASE_MEASUREMENT_ID" ]; then

      warn "  Firebase Measurement ID is empty."
      warn "  Skipping this optional value."

      continue

    fi

    warn "  No value supplied. Skipping ${SECRET_NAME}."

    continue

  fi


  # ---------------------------------------------------------------------------
  # Compare Existing Secret Value
  # ---------------------------------------------------------------------------

  LATEST_VERSION=$(
    gcloud secrets versions access latest \
      --secret="$SECRET_NAME" \
      --project="$PROJECT_ID" \
      2>/dev/null || echo ""
  )

  if [ "$LATEST_VERSION" = "$SECRET_VALUE" ]; then

    success "  Secret ${SECRET_NAME} is already up-to-date."
    continue

  fi


  # ---------------------------------------------------------------------------
  # Make Sure the Secret Exists
  # ---------------------------------------------------------------------------

  if ! gcloud secrets describe "$SECRET_NAME" \
      --project="$PROJECT_ID" \
      >/dev/null 2>&1; then

    warn "  Secret ${SECRET_NAME} does not exist."
    warn "  It should normally have been created by Terraform."

    info "  Creating Secret Manager secret ${SECRET_NAME}..."

    gcloud secrets create "$SECRET_NAME" \
      --project="$PROJECT_ID" \
      --replication-policy="automatic" \
      --quiet

  fi


  # ---------------------------------------------------------------------------
  # Add New Secret Version
  # ---------------------------------------------------------------------------

  printf "%s" "$SECRET_VALUE" |
    gcloud secrets versions add "$SECRET_NAME" \
      --data-file="-" \
      --project="$PROJECT_ID" \
      --quiet

  success "  Successfully updated ${SECRET_NAME}."

done


# ==============================================================================
# Complete
# ==============================================================================

success "All required secrets have been processed."
