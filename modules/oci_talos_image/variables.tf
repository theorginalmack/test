variable "compartment_id" {
  description = "The compartment id"
  type        = string
}

variable "images_bucket" {
  description = "Name for bucket used to store custom images"
  nullable    = false
  type        = string
}

variable "image_file" {
  description = "Absolute path to the Oracle image archive to upload."
  nullable    = false
  type        = string
}

variable "talos_version" {
  description = "Talos version for the uploaded Oracle image."
  nullable    = false
  type        = string
}
