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

PROJECT_ID="sbd-ai-poc-h"
REGION="us-central1"
NETWORK="proj-sbd-ai-poc-h-sopke-vnet"
SUBNET="proj-sbd-ai-poc-h-sopke-vnet-subnet"
SERVICE_ACCOUNT="gcc-creative-studio-dev-sa@sbd-ai-poc-h.iam.gserviceaccount.com"

BE_SERVICE="cstudio-be"

echo "=========================================================="
echo " Deploying Backend Patch with Private DB Connector IP     "
echo "=========================================================="

TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%s)
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/cs-be-development-repo/${BE_SERVICE}:${TAG}"

echo ">> Step 1: Building Backend Container Image (with BuildKit)..."
gcloud builds submit backend \
  --config=backend/cloudbuild-patch.yaml \
  --substitutions="_IMAGE=${IMAGE}" \
  --project="$PROJECT_ID"

echo ">> Step 2: Deploying Backend ($BE_SERVICE) to Cloud Run in Spoke VPC..."
gcloud run deploy "$BE_SERVICE" \
  --image="$IMAGE" \
  --region="$REGION" \
  --ingress="internal" \
  --network="$NETWORK" \
  --subnet="$SUBNET" \
  --service-account="$SERVICE_ACCOUNT" \
  --vpc-egress=all-traffic \
  --project="$PROJECT_ID"
   

