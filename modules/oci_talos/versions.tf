terraform {
  required_version = ">= 0.13"

  required_providers {
    oci = {
      source = "oracle/oci"
    }

    talos = {
      source = "siderolabs/talos"
    }
  }
}