resource "proxmox_virtual_environment_pool" "proxmox_resource_pool" {
  comment = "Resources pertaining to the ${var.kubernetes_cluster_name} Kubernetes Cluster"
  pool_id = "${var.kubernetes_cluster_name}_kubernetes"
}