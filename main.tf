resource "oci_identity_compartment" "compartment" {
  compartment_id = var.tenancy_ocid
  description    = var.compartment_description
  name           = var.compartment_name
}

module "oci_vcn" {
  source = "oracle-terraform-modules/vcn/oci"

  compartment_id                = oci_identity_compartment.compartment.id
  create_internet_gateway       = true
  create_nat_gateway            = true
  create_service_gateway        = true
  internet_gateway_display_name = var.internet_gateway_display_name
  nat_gateway_display_name      = var.nat_gateway_display_name
  vcn_name                      = var.vcn_name

  subnets = {
    public = {
      cidr_block = "10.0.0.0/24"
      name       = var.public_subnet_name
      type       = "public"
    }
    private = {
      cidr_block = "10.0.1.0/24"
      name       = var.private_subnet_name
      type       = "private"
    }
  }
}

resource "oci_core_default_security_list" "default_security_list" {
  manage_default_resource_id = module.oci_vcn.default_security_list_id
  display_name               = "Default Security List for ${var.vcn_name}"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "${module.oci_vcn.nat_gateway_all_attributes[0].nat_ip}/32"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "${oci_network_load_balancer_network_load_balancer.talos_nlb.ip_addresses[0]["ip_address"]}/32"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "10.0.0.0/8"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "${var.personal_ip}/32"
  }

  ingress_security_rules {
    protocol = 6
    source   = "0.0.0.0/0"

    tcp_options {
      max = 6443
      min = 6443
    }
  }

  ingress_security_rules {
    protocol = 6
    source   = "0.0.0.0/0"

    tcp_options {
      max = 50001
      min = 50000
    }
  }

  ingress_security_rules {
    protocol = 17
    source   = "0.0.0.0/0"

    udp_options {
      max = 51820
      min = 51820
    }
  }

  ingress_security_rules {
    protocol = 17
    source   = "0.0.0.0/0"

    udp_options {
      max = 51871
      min = 51871
    }
  }
}

module "oci_talos_image" {
  source = "./modules/oci_talos_image"

  compartment_id = oci_identity_compartment.compartment.id
  images_bucket  = var.talos_images_bucket
}

resource "oci_network_load_balancer_network_load_balancer" "talos_nlb" {
  compartment_id = oci_identity_compartment.compartment.id
  display_name   = "talos-nlb"
  is_private     = false
  subnet_id      = module.oci_vcn.subnet_all_attributes["public"]["id"]
}

module "talos" {
  source = "./modules/talos"

  cluster_endpoints = compact([
    var.cluster_domain_endpoint,
    oci_network_load_balancer_network_load_balancer.talos_nlb.ip_addresses[0]["ip_address"],
  ])
  controlplane_node_ips = module.oci_talos.controlplane_node_ips
  worker_node_ips       = module.oci_talos.worker_node_ips
}

module "oci_talos" {
  source = "./modules/oci_talos"

  ad_number              = var.ad_number
  arm64_image_id         = module.oci_talos_image.arm64_image_id
  compartment_id         = oci_identity_compartment.compartment.id
  controlplane_user_data = module.talos.controlplane_machine_configuration
  nlb_id                 = oci_network_load_balancer_network_load_balancer.talos_nlb.id
  subnet_id              = module.oci_vcn.subnet_all_attributes["private"]["id"]
  worker_user_data       = module.talos.worker_machine_configuration
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

data "github_repository" "this" {
  name = var.flux_repository_name
}

resource "github_repository_deploy_key" "this" {
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "false"
  repository = data.github_repository.this.name
  title      = "FluxCD"
}

provider "helm" {
  kubernetes = {
    client_certificate     = base64decode(module.talos.kubeconfig.client_certificate)
    client_key             = base64decode(module.talos.kubeconfig.client_key)
    cluster_ca_certificate = base64decode(module.talos.kubeconfig.ca_certificate)
    host                   = module.talos.kubeconfig.host
  }
}

resource "helm_release" "cilium" {
  chart        = "cilium"
  force_update = true
  name         = "cilium"
  namespace    = "kube-system"
  repository   = "https://helm.cilium.io"
  version      = "1.18.7"

  set = [
    {
      name  = "bandwidthManager.enabled"
      value = true
    },
    {
      name  = "bpf.datapathMode"
      value = "netkit"
    },
    {
      name  = "bpf.hostLegacyRouting"
      value = true
    },
    {
      name  = "bpf.masquerade"
      value = true
    },
    {
      name  = "bpf.tproxy"
      value = false
    },
    {
      name  = "bpfClockProbe"
      value = true
    },
    {
      name  = "cgroup.autoMount.enabled"
      value = false
    },
    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    },
    {
      name  = "envoy.enabled"
      value = false
    },
    {
      name  = "hubble.relay.enabled"
      value = true
    },
    {
      name  = "hubble.ui.enabled"
      value = true
    },
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },
    {
      name  = "ipv4NativeRoutingCIDR"
      value = "10.244.0.0/16"
    },
    {
      name  = "k8sNetworkPolicy.enabled"
      value = false
    },
    {
      name  = "k8sServiceHost"
      value = "localhost"
    },
    {
      name  = "k8sServicePort"
      value = "7445"
    },
    {
      name  = "kubeProxyReplacement"
      value = true
    },
    {
      name  = "l7Proxy"
      value = false
    },
    {
      name  = "operator.prometheus.enabled"
      value = true
    },
    {
      name  = "rollOutCiliumPods"
      value = true
    },
    {
      name  = "routingMode"
      value = "native"
    },
    {
      name  = "securityContext.capabilities.ciliumAgent"
      value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
    },
    {
      name  = "securityContext.capabilities.cleanCiliumState"
      value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    },
  ]
}

provider "flux" {
  git = {
    url = "ssh://git@github.com/${data.github_repository.this.full_name}.git"
    ssh = {
      private_key = tls_private_key.flux.private_key_pem
      username    = "git"
    }
  }

  kubernetes = {
    client_certificate     = base64decode(module.talos.kubeconfig.client_certificate)
    client_key             = base64decode(module.talos.kubeconfig.client_key)
    cluster_ca_certificate = base64decode(module.talos.kubeconfig.ca_certificate)
    host                   = module.talos.kubeconfig.host
  }
}

resource "flux_bootstrap_git" "talos_cluster" {
  interval       = "5m"
  network_policy = false
  path           = var.flux_repository_path

  provisioner "local-exec" {
    command = <<EOT
      curl -sL https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.34.0/kubeseal-0.34.0-linux-amd64.tar.gz | tar -xz
    EOT
  }
}

module "sealed_secret_cert" {
  source = "matti/resource/shell"

  command    = "kubeseal --fetch-cert --controller-name=sealed-secrets-controller --controller-namespace=flux-system"
  depends_on = [flux_bootstrap_git.talos_cluster]
}

resource "github_repository_file" "sealed_secret_cert" {
  branch              = "main"
  commit_message      = "Add Sealed Secrets public certificate"
  content             = base64encode(module.sealed_secret_cert.stdout)
  file                = "${var.flux_repository_path}/pub-sealed-secrets.pem"
  overwrite_on_create = true
  repository          = data.github_repository.this.name
}
