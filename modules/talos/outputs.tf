output "controlplane_machine_configuration" {
  value = data.talos_machine_configuration.controlplane.machine_configuration
}

output "kubeconfig" {
  value = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration
}

output "worker_machine_configuration" {
  value = data.talos_machine_configuration.worker.machine_configuration
}