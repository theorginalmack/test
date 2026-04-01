output "controlplane_machine_configuration" {
  sensitive = true
  value     = data.talos_machine_configuration.controlplane.machine_configuration
}

output "kubeconfig" {
  sensitive = true
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration
}

output "talosconfig" {
  sensitive = true
  value     = data.talos_client_configuration.this.talos_config
}

output "worker_machine_configuration" {
  sensitive = true
  value     = data.talos_machine_configuration.worker.machine_configuration
}
