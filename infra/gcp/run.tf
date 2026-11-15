resource "google_service_account" "run" {
  account_id   = "${var.name}-run"
  display_name = "PetClinic Cloud Run runtime"
}

resource "google_secret_manager_secret_iam_member" "run_reads_db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run.email}"
}

resource "google_cloud_run_v2_service" "petclinic" {
  name                = var.name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = google_service_account.run.email

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = google_compute_network.main.id
        subnetwork = google_compute_subnetwork.run.id
      }
    }

    containers {
      # Placeholder for the first apply. The deploy workflow sets the real image afterwards,
      # which is why Terraform ignores changes to it below.
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "postgres"
      }
      env {
        name  = "POSTGRES_URL"
        value = "jdbc:postgresql://${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.petclinic.name}?sslmode=require"
      }
      env {
        name  = "POSTGRES_USER"
        value = google_sql_user.petclinic.name
      }
      env {
        name = "POSTGRES_PASS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      # Upstream exposes every actuator endpoint, which is fine on a laptop but not on the internet.
      env {
        name  = "MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE"
        value = "health,info"
      }

      startup_probe {
        http_get {
          path = "/actuator/health"
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        failure_threshold     = 24
      }

      liveness_probe {
        http_get {
          path = "/actuator/health"
        }
        period_seconds = 30
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [
    google_secret_manager_secret_iam_member.run_reads_db_password,
    google_secret_manager_secret_version.db_password,
  ]
}

# A public demo: anyone can open the site.
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.petclinic.name
  location = google_cloud_run_v2_service.petclinic.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
