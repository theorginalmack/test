output "controlplane_machine_configuration" {
  description = "Rendered Talos machine configuration for controlplane nodes."
  sensitive   = true
  value       = module.talos.controlplane_machine_configuration
}

output "kubeconfig" {
  description = "Kubernetes client configuration returned by talos_cluster_kubeconfig."
  sensitive   = true
  value       = module.talos.kubeconfig
}

output "talosconfig" {
  description = "Talos client configuration rendered for the cluster."
  sensitive   = true
  value       = module.talos.talosconfig
}

output "worker_machine_configuration" {
  description = "Rendered Talos machine configuration for worker nodes."
  sensitive   = true
  value       = module.talos.worker_machine_configuration
}
