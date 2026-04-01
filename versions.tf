terraform {
  required_version = ">= 1.5.0"

  required_providers {
    flux = {
      source = "fluxcd/flux"
    }

    github = {
      source = "integrations/github"
    }

    oci = {
      source = "oracle/oci"
    }

    tls = {
      source = "hashicorp/tls"
    }
  }
}
