variable "ad_number" {
  description = "The AD number for your A1 flex instance on Oracle"
  default     = 1
  type        = number
}

variable "cluster_domain_endpoint" {
  default     = ""
  description = "The cluster domain endpoint (empty if you don't have one)."
  type        = string
}

variable "compartment_description" {
  default     = "Default compartment"
  description = "A description of the compartment."
  type        = string
}

variable "compartment_name" {
  default     = "default-compartment"
  description = "The name of the compartment."
  type        = string
}

variable "flux_repository_name" {
  default     = "fleet-infra"
  description = "The name of the Github repository that stores your Flux configuration."
  type        = string
}

variable "flux_repository_path" {
  default     = "clusters/talos-cluster"
  description = "The path in the Git repository to the local directory that stores your Flux configuration."
  type        = string
}

variable "fingerprint" {
  description = "The oci_fingerprint to auth to Oracle Cloud"
  nullable    = false
  type        = string
}

variable "internet_gateway_display_name" {
  default     = "igw"
  description = "The display name of the internet gateway."
  type        = string
}

variable "nat_gateway_display_name" {
  default     = "ngw"
  description = "The display name of the NAT gateway."
  type        = string
}

variable "personal_ip" {
  description = "The personal IP address."
  nullable    = false
  sensitive   = true
  type        = string

  validation {
    condition = (
      var.personal_ip == "" ||
      can(regex("(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]", var.personal_ip))
    )
    error_message = "The personal IP must be an empty string or a valid IP address (e.g., 1.1.1.1)."
  }
}

variable "private_key" {
  description = "The OCI private key."
  nullable    = false
  sensitive   = true
  type        = string
}

variable "private_subnet_name" {
  default     = "private"
  description = "The name of the private subnet."
  type        = string
}

variable "public_subnet_name" {
  default     = "public"
  description = "The name of the public subnet."
  type        = string
}

variable "region" {
  description = "The oci_region to auth to Oracle Cloud"
  nullable    = false
  type        = string
}

variable "talos_images_bucket" {
  description = "The name of the bucket that stores the Talos images."
  nullable    = false
  type        = string
}

variable "tenancy_ocid" {
  description = "The tenancy to auth to Oracle Cloud"
  nullable    = false
  type        = string
}

variable "user_ocid" {
  description = "The user to auth to Oracle Cloud"
  nullable    = false
  type        = string
}

variable "vcn_name" {
  default     = "vcn"
  description = "The name of the Virtual Cloud Network (VCN)."
  type        = string
}
