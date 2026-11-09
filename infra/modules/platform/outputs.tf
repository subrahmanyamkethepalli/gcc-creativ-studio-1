output "internal_app_url" {
  description = "Private application URL. Empty while Internal LB is disabled."
  value       = var.internal_app_url != "" ? trimsuffix(var.internal_app_url, "/") : ""
}

output "frontend_service_url" {
  description = "Frontend URL. Empty while Internal LB is disabled."
  value       = var.internal_app_url != "" ? trimsuffix(var.internal_app_url, "/") : ""
}

output "backend_service_url" {
  description = "Backend Cloud Run service URL."
  value       = local.backend_url
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL instance connection name."
  value       = module.postgresql.connection_name
}

output "frontend_secrets" {
  description = "Frontend Secret Manager secret names."
  value       = var.frontend_secrets
}

output "backend_secrets" {
  description = "Backend Secret Manager secret names."
  value       = var.backend_secrets
}
