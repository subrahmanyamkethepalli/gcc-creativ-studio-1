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


output "ip_address" {
  description = "Private IP address of the Internal Application Load Balancer."
  value       = google_compute_address.this.address
}


output "url_map_id" {
  description = "Regional URL map resource ID."
  value       = google_compute_region_url_map.this.id
}


output "frontend_neg_id" {
  description = "Frontend Cloud Run serverless NEG ID."
  value       = google_compute_region_network_endpoint_group.frontend.id
}


output "backend_neg_id" {
  description = "Backend Cloud Run serverless NEG ID."
  value       = google_compute_region_network_endpoint_group.backend.id
}


output "frontend_backend_service_id" {
  description = "Frontend regional backend service ID."
  value       = google_compute_region_backend_service.frontend.id
}


output "backend_backend_service_id" {
  description = "Backend regional backend service ID."
  value       = google_compute_region_backend_service.backend.id
}


output "forwarding_rule_id" {
  description = "Internal HTTPS forwarding rule ID."
  value       = google_compute_forwarding_rule.https.id
}


output "proxy_only_subnet_id" {
  description = "Proxy-only subnet ID."
  value       = google_compute_subnetwork.proxy_only.id
}

*/