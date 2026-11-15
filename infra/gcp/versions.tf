terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # For real use, keep state in a bucket:
  # backend "gcs" {
  #   bucket = "my-terraform-state"
  #   prefix = "petclinic"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
