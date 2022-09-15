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
