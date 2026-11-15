variable "project_id" {
  description = "Google Cloud project to deploy into."
  type        = string
}

variable "region" {
  description = "Region for every resource. me-central2 is Dammam, Saudi Arabia."
  type        = string
  default     = "me-central2"
}

variable "name" {
  description = "Name prefix for resources."
  type        = string
  default     = "petclinic"
}

variable "db_tier" {
  description = "Cloud SQL machine type. db-f1-micro is the cheapest shared-core tier."
  type        = string
  default     = "db-f1-micro"
}

variable "max_instances" {
  description = "Upper limit for Cloud Run instances, to cap cost."
  type        = number
  default     = 2
}

variable "github_repository" {
  description = "owner/repo allowed to deploy through Workload Identity Federation. Empty disables it."
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Protect the database from terraform destroy. Turn on for anything you care about."
  type        = bool
  default     = false
}
