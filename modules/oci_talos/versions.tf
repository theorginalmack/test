terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source = "oracle/oci"
    }

    talos = {
      source = "siderolabs/talos"
    }
  }
}
