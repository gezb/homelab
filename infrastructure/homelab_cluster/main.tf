
provider "proxmox" {
  endpoint = "https://${var.proxmox_hostname}/"
}

module "homelab" {
  source                      = "../modules/talos_cluster"
  proxmox_hostname            = var.proxmox_hostname
  proxmox_ssh_hostname        = var.proxmox_ssh_hostname
  proxmox_ssh_key_path        = var.proxmox_ssh_key_path
  proxmox_snippets_datastore  = var.proxmox_snippets_datastore
  talos_version               = "v1.7.6"
  kubernetes_version          = "v1.30.3"
  controlplane_virtual_ip     = var.controlplane_virtual_ip
  dns_server                  = var.dns_server
  vm_id_prefix                = var.vm_id_prefix
  network_id_prefix           = var.network_id_prefix
  kubernetes_cluster_name     = "homelab"
  controlplane_num            = 3
  controlplane_proxmox_nodes  = ["proxmox1", "proxmox2", "proxmox3"]
  controlplane_host_id_prefix = "10"
  controlplane_datastore      = "zfs"
  controlplane_gateway        = var.dns_server
  workernode_num              = 1
  workernode_proxmox_nodes    = ["proxmox2", "proxmox3"]
  workernode_host_id_prefix   = "11"
  workernode_datastore        = "zfs"
  workernode_gateway          = var.dns_server
  workernode_memory           = 20980
  argocd_enabled              = false
  argocd_install_manifest     = var.argocd_install_manifest
  argocd_repo                 = var.argocd_repo
  argocd_project_path         = var.argocd_project_path
}


output "kubeconfig" {
  value     = module.homelab.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value     = module.homelab.talosconfig
  sensitive = true
}
