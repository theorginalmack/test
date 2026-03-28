variable "ad_number" {
  default     = 3
  description = "The AD number for your A1 flex instance on Oracle"
  nullable    = false
  type        = number
}

variable "arm64_image_id" {
  description = "The Talos ARM64 image id"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id"
  type        = string
}

variable "controlplane_user_data" {
  description = "The controlplane userdata"
  type        = string
}

variable "nlb_id" {
  description = "The network load balancer id"
  type        = string
}

variable "subnet_id" {
  description = "The private subnet id"
  type        = string
}

variable "worker_user_data" {
  description = "The worker userdata"
  type        = string
}