resource "talos_machine_secrets" "secrets" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.kubernetes_cluster_name
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoints            = [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix)]
  nodes = concat(
    [for node in [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip] : node],
    [for node in [for ip in toset(flatten(proxmox_virtual_environment_vm.workernode.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix)] : node]
  )
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoint             = [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip][0]
  node                 = [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip][0]
}

resource "talos_machine_bootstrap" "bootstrap" {
  count = var.controlplane_num
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]
  endpoint             = [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip][0]
  node                 = [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip][0]
  client_configuration = talos_machine_secrets.secrets.client_configuration
}

output "kubeconfig" {
  value     = resource.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}
