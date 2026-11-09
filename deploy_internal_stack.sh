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

set -euo pipefail

# ==========================================================
# Configuration
# ==========================================================

PROJECT_ID="sbd-ai-poc-h"
REGION="us-central1"

FE_SERVICE="cstudio-fe"

NETWORK="proj-sbd-ai-poc-h-sopke-vnet"
SUBNET="proj-sbd-ai-poc-h-sopke-vnet-subnet"

SERVICE_ACCOUNT="gcc-creative-studio-dev-sa@sbd-ai-poc-h.iam.gserviceaccount.com"

ARTIFACT_REPOSITORY="cs-be-development-repo"


echo "=========================================================="
echo " Deploying Creative Studio Frontend to Private Cloud Run"
echo " Project : ${PROJECT_ID}"
echo " Region  : ${REGION}"
echo " Service : ${FE_SERVICE}"
echo "=========================================================="


# ==========================================================
# STEP 1: Build and deploy frontend Cloud Run service
# ==========================================================

REBUILD="${1:-}"

if [[ "$REBUILD" == "--rebuild" ]] || \
   ! gcloud run services describe "$FE_SERVICE" \
     --region="$REGION" \
     --project="$PROJECT_ID" \
     >/dev/null 2>&1; then

  # --------------------------------------------------------
  # Step 1a: Build frontend image
  # --------------------------------------------------------

  echo ">> Step 1a: Building Frontend Container Image..."

  TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%s)

  IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPOSITORY}/${FE_SERVICE}:${TAG}"

  echo "Image: ${IMAGE}"

  gcloud builds submit frontend \
    --tag="${IMAGE}" \
    --project="$PROJECT_ID"


  # --------------------------------------------------------
  # Step 1b: Deploy frontend to Cloud Run
  # --------------------------------------------------------

  echo ">> Step 1b: Deploying ${FE_SERVICE} to private Cloud Run..."

  gcloud run deploy "$FE_SERVICE" \
    --image="$IMAGE" \
    --region="$REGION" \
    --port=8080 \
    --ingress=internal \
    --network="$NETWORK" \
    --subnet="$SUBNET" \
    --vpc-egress=all-traffic \
    --service-account="$SERVICE_ACCOUNT" \
    --allow-unauthenticated \
    --project="$PROJECT_ID" \
    --quiet

else

  echo ">> Frontend service ${FE_SERVICE} already exists."
  echo ">> Skipping build and deployment."
  echo ">> Run './deploy_internal_stack.sh --rebuild' to redeploy."

fi


# ==========================================================
# Completed
# ==========================================================

echo
echo "=========================================================="
echo " Frontend Cloud Run Deployment Complete"
echo
echo " Cloud Run Service : ${FE_SERVICE}"
echo " Project           : ${PROJECT_ID}"
echo " Region            : ${REGION}"
echo " Network           : ${NETWORK}"
echo " Subnet            : ${SUBNET}"
echo " Service Account   : ${SERVICE_ACCOUNT}"
echo
echo " Internal Load Balancer resources are managed by Terraform:"
echo "   - ${FE_SERVICE}-neg"
echo "   - ${FE_SERVICE}-backend"
echo "   - cstudio-be-neg"
echo "   - cstudio-be-backend"
echo "   - URL map"
echo "   - HTTPS proxy"
echo "   - Internal forwarding rule"
echo "   - Internal IP"
echo "   - Proxy-only subnet"
echo "=========================================================="