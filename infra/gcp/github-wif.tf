# GitHub Actions signs in with a short-lived token from Workload Identity Federation,
# so no service account key is ever created or stored in GitHub.

locals {
  wif_enabled = var.github_repository != ""
}

resource "google_iam_workload_identity_pool" "github" {
  count                     = local.wif_enabled ? 1 : 0
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.enabled]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count                              = local.wif_enabled ? 1 : 0
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Only the main branch of this one repository may deploy.
  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.ref == 'refs/heads/main'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deployer" {
  count        = local.wif_enabled ? 1 : 0
  account_id   = "${var.name}-deployer"
  display_name = "PetClinic GitHub deployer"
}

resource "google_service_account_iam_member" "github_impersonates_deployer" {
  count              = local.wif_enabled ? 1 : 0
  service_account_id = google_service_account.deployer[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${var.github_repository}"
}

resource "google_artifact_registry_repository_iam_member" "deployer_pushes_images" {
  count      = local.wif_enabled ? 1 : 0
  repository = google_artifact_registry_repository.images.name
  location   = google_artifact_registry_repository.images.location
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer[0].email}"
}

resource "google_cloud_run_v2_service_iam_member" "deployer_updates_service" {
  count    = local.wif_enabled ? 1 : 0
  name     = google_cloud_run_v2_service.petclinic.name
  location = google_cloud_run_v2_service.petclinic.location
  role     = "roles/run.developer"
  member   = "serviceAccount:${google_service_account.deployer[0].email}"
}

# Deploying a revision that runs as the runtime service account requires acting as it.
resource "google_service_account_iam_member" "deployer_acts_as_runtime" {
  count              = local.wif_enabled ? 1 : 0
  service_account_id = google_service_account.run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer[0].email}"
}
