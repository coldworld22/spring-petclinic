output "url" {
  description = "Public URL of PetClinic."
  value       = google_cloud_run_v2_service.petclinic.uri
}

output "image_repository" {
  description = "Where the deploy workflow pushes images."
  value       = local.image_repository
}

output "workload_identity_provider" {
  description = "Set as the GCP_WORKLOAD_IDENTITY_PROVIDER repository variable."
  value       = local.wif_enabled ? google_iam_workload_identity_pool_provider.github[0].name : null
}

output "deployer_service_account" {
  description = "Set as the GCP_DEPLOY_SERVICE_ACCOUNT repository variable."
  value       = local.wif_enabled ? google_service_account.deployer[0].email : null
}
