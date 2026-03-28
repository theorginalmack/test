resource "oci_network_load_balancer_backend_set" "controlplane" {
  is_preserve_source       = false
  name                     = "controlplane"
  network_load_balancer_id = var.nlb_id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol           = "HTTPS"
    port               = 6443
    url_path           = "/readyz"
    return_code        = 401
    interval_in_millis = 15000
  }
}

resource "oci_network_load_balancer_backend_set" "controlplane_talos" {
  is_preserve_source       = false
  name                     = "controlplane-talos"
  network_load_balancer_id = var.nlb_id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol           = "TCP"
    port               = 50000
    interval_in_millis = 30000
  }
}

resource "oci_network_load_balancer_listener" "controlplane" {
  default_backend_set_name = oci_network_load_balancer_backend_set.controlplane.name
  name                     = "controlplane"
  network_load_balancer_id = var.nlb_id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_listener" "controlplane_talos" {
  default_backend_set_name = oci_network_load_balancer_backend_set.controlplane_talos.name
  name                     = "controlplane-talos"
  network_load_balancer_id = var.nlb_id
  port                     = 50000
  protocol                 = "TCP"
}

module "controlplane_instance_group" {
  source = "oracle-terraform-modules/compute-instance/oci"

  ad_number                   = var.ad_number
  boot_volume_size_in_gbs     = 100
  compartment_ocid            = var.compartment_id
  instance_count              = 1
  instance_display_name       = "Talos ARM64 Master"
  instance_flex_ocpus         = 2
  instance_flex_memory_in_gbs = 12
  shape                       = "VM.Standard.A1.Flex"
  source_ocid                 = var.arm64_image_id
  ssh_public_keys             = ""
  subnet_ocids                = [var.subnet_id]
  user_data                   = base64encode(var.controlplane_user_data)

  cloud_agent_plugins = {
    "autonomous_linux" : "DISABLED",
    "bastion" : "DISABLED",
    "block_volume_mgmt" : "DISABLED",
    "custom_logs" : "DISABLED",
    "java_management_service" : "DISABLED",
    "management" : "DISABLED",
    "monitoring" : "DISABLED",
    "osms" : "DISABLED",
    "run_command" : "DISABLED",
    "vulnerability_scanning" : "DISABLED"
  }
}

module "worker_instance_group" {
  depends_on = [module.controlplane_instance_group]
  source     = "oracle-terraform-modules/compute-instance/oci"

  ad_number                   = var.ad_number
  boot_volume_size_in_gbs     = 100
  compartment_ocid            = var.compartment_id
  instance_count              = 1
  instance_display_name       = "Talos ARM64 Worker"
  instance_flex_ocpus         = 2
  instance_flex_memory_in_gbs = 12
  shape                       = "VM.Standard.A1.Flex"
  source_ocid                 = var.arm64_image_id
  ssh_public_keys             = ""
  subnet_ocids                = [var.subnet_id]
  user_data                   = base64encode(var.worker_user_data)

  cloud_agent_plugins = {
    "autonomous_linux" : "DISABLED",
    "bastion" : "DISABLED",
    "block_volume_mgmt" : "DISABLED",
    "custom_logs" : "DISABLED",
    "java_management_service" : "DISABLED",
    "management" : "DISABLED",
    "monitoring" : "DISABLED",
    "osms" : "DISABLED",
    "run_command" : "DISABLED",
    "vulnerability_scanning" : "DISABLED"
  }
}

resource "oci_network_load_balancer_backend" "controlplane" {
  backend_set_name         = oci_network_load_balancer_backend_set.controlplane.name
  name                     = "controlplane-1"
  network_load_balancer_id = var.nlb_id
  port                     = 6443
  target_id                = module.controlplane_instance_group.instance_id[0]
}

resource "oci_network_load_balancer_backend" "controlplane_talos" {
  backend_set_name         = oci_network_load_balancer_backend_set.controlplane_talos.name
  network_load_balancer_id = var.nlb_id
  port                     = 50000
  name                     = "controlplane-talos-1"
  target_id                = module.controlplane_instance_group.instance_id[0]
}