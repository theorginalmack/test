variable "cluster_endpoints" {
  description = "The cluster endpoints"
  type        = list(string)
}

variable "cluster_name" {
  default     = "talos-cluster"
  description = "The cluster name"
  type        = string
}

variable "config_patches" {
  default     = []
  description = "The machine configuration config patch"
  type        = list(string)
}

variable "controlplane_node_ips" {
  description = "The control plane node ips"
  type        = list(string)
}

variable "kubernetes_version" {
  default     = "1.35.1"
  description = "The version of Kubernetes to use for the cluster."
  type        = string

  validation {
    condition     = can(regex("^(1\\.[1-9][0-9]*\\.[0-9]+)$", var.kubernetes_version))
    error_message = "The Kubernetes version must be a valid version string in the format '1.x.y' where x and y are numbers (e.g., 1.24.0)."
  }
}

variable "talos_version" {
  description = "The version of Talos to use for the cluster."
  type        = string
  default     = "v1.12.4"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.talos_version))
    error_message = "The Talos version must be a valid version string in the format 'vX.Y.Z' where X, Y, and Z are numbers (e.g., v1.7.6)."
  }
}

variable "worker_node_ips" {
  description = "The worker plane node ips"
  type        = list(string)
}
