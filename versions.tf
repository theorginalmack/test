terraform {
  required_version = ">= 0.13"

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