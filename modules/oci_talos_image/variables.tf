variable "compartment_id" {
  description = "The compartment id"
  type        = string
}

variable "images_bucket" {
  description = "Name for bucket used to store custom images"
  nullable    = false
  type        = string
}