variable "project" {
  description = "Specify the GCP project."
  type        = string
}

variable "credentials_file" {
  description = "Specify the GCP credentials .json file."
  type        = string
}

variable "region" {
  description = "Specify the GCP region."
  type        = string
  default     = "europe-west6"
}

variable "zone" {
  description = "Specify the GCP zone."
  type        = string
  default     = "europe-west6-b"
}

variable "service_list" {
  description = "Specify APIs required by the project."
  type        = list(string)
  default = [
    "iam.googleapis.com",
    # Cloud Resource Manager API needs to be enabled manually according to
    # https://github.com/hashicorp/terraform-provider-google/issues/6101
    # When running terraform for the first time in the project you will see
    # an error message with link to Cloud Console to enable this API.
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com"
  ]
}

variable "wghub_instance_image_project" {
  description = "Specify the boot image project name."
  type        = string
  default     = "ubuntu-os-pro-cloud"
}

variable "wghub_instance_image_family" {
  description = "Specify the boot image family name."
  type        = string
  default     = "ubuntu-pro-2204-lts"
}
