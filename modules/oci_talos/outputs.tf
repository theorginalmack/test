output "controlplane_node_ips" {
  value = [module.controlplane_instance_group.private_ip[0]]
}

output "worker_node_ips" {
  value = [module.worker_instance_group.private_ip[0]]
}