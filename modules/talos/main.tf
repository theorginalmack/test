locals {
  all_node_patch = yamlencode({
    cluster = {
      allowSchedulingOnControlPlanes = true
    }

    machine = {
      certSANs = var.cluster_endpoints

      features = {
        hostDNS = {
          enabled              = true
          forwardKubeDNSToHost = true
          resolveMemberNames   = true
        }

        kubePrism = {
          enabled = true
          port    = 7445
        }
      }

      install = {
        image = data.talos_image_factory_urls.this.urls.installer
      }

      kubelet = {
        registerWithFQDN = false
      }

      network = {
        interfaces = [
          {
            addresses = ["169.254.2.53/32"]
            interface = "dummy0"
          }
        ]

        kubespan = {
          advertiseKubernetesNetworks = false
          allowDownPeerBypass         = true
          enabled                     = true
        }

        nameservers = [
          "100.100.100.100",
          "1.1.1.1",
        ]
      }

      sysctls = {
        "net.core.rmem_max"                = "2500000"
        "net.core.wmem_max"                = "2500000"
        "net.ipv4.conf.all.src_valid_mark" = "1"
      }

      time = {
        servers = [
          "169.254.169.123",
          "169.254.169.254",
          "time.cloudflare.com"
        ]
      }
    }
  })
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version
  filters = {
    names = [
      "crun"
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "this" {
  architecture  = "arm64"
  platform      = "oracle"
  schematic_id  = talos_image_factory_schematic.this.id
  talos_version = data.talos_image_factory_extensions_versions.this.talos_version
}

resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.cluster_name
  endpoints            = var.cluster_endpoints
  nodes                = concat(var.controlplane_node_ips, var.worker_node_ips)
}

data "talos_machine_configuration" "controlplane" {
  cluster_endpoint   = "https://${var.cluster_endpoints[0]}:6443"
  cluster_name       = var.cluster_name
  config_patches     = concat([local.all_node_patch], var.config_patches)
  docs               = false
  examples           = false
  kubernetes_version = var.kubernetes_version
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "controlplane"
  talos_version      = var.talos_version
}

resource "talos_machine_bootstrap" "controlplane" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.cluster_endpoints[0]
  node                 = var.controlplane_node_ips[0]
}

data "talos_machine_configuration" "worker" {
  cluster_endpoint   = "https://${var.cluster_endpoints[0]}:6443"
  cluster_name       = var.cluster_name
  config_patches     = concat([local.all_node_patch], var.config_patches)
  docs               = false
  examples           = false
  kubernetes_version = var.kubernetes_version
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "worker"
  talos_version      = var.talos_version
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.cluster_endpoints[0]
  node                 = var.controlplane_node_ips[0]
  timeouts = {
    read = "30s"
  }
}
