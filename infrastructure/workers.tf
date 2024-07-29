locals {
  workernode_details = flatten([
    [
      for i in range(var.workernode_num) :
      {
        id           = "${var.vm_id_prefix}${var.workernode_host_id_prefix}${i + 1}"
        name         = "${var.workernode_hostname_prefix}-${i + 1}"
        proxmox_node = element(var.workernode_proxmox_nodes, i)
        ipv4         = "${var.network_id_prefix}.${var.workernode_host_id_prefix}${i + 1}/24"

      }
    ]
  ])
}

resource "proxmox_virtual_environment_vm" "workernode" {
  count = var.workernode_num
  vm_id = local.workernode_details[count.index].id

  pool_id   = proxmox_virtual_environment_pool.proxmox_resource_pool.id
  node_name = local.workernode_details[count.index].proxmox_node

  name        = local.workernode_details[count.index].name
  description = local.workernode_details[count.index].name
  tags        = var.workernode_tags

  mac_addresses =  var.network_dhcp ? [ var.network_dhcp_mac_addresses[count.index] ] : []


  cpu {
    cores = var.workernode_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.workernode_memory
  }

  network_device {
    bridge = var.workernode_network_device
    mac_address = var.network_dhcp ? var.network_dhcp_mac_addresses[var.controlplane_num + count.index] : ""
  }

  initialization {
    datastore_id = var.workernode_datastore
    ip_config {

      dynamic "ipv4" {

        for_each = var.network_dhcp ? ["apply"] : []
        content {
          address = "dhcp"
        }
      }
      dynamic "ipv4" {
        for_each = var.network_dhcp ? [] : ["apply"]
        content {
          address = local.workernode_details[count.index].ipv4
          gateway = var.controlplane_gateway
        }
      }
    }
    meta_data_file_id = proxmox_virtual_environment_file.workernode_metadata[count.index].id
  }

  disk {
    datastore_id = var.workernode_datastore
    file_id      = proxmox_virtual_environment_file.talos_image.id
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.workernode_disk_size
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }
}

resource "proxmox_virtual_environment_file" "workernode_metadata" {
  count        = var.workernode_num
  node_name    = local.workernode_details[count.index].proxmox_node
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_datastore

  source_raw {
    data = templatefile("${path.module}/configs/metadata.yaml", {
      hostname : local.workernode_details[count.index].name,
      id : local.workernode_details[count.index].id,
      providerID : "proxmox://homelab/${local.workernode_details[count.index].proxmox_node}",
      type : "${var.workernode_cpu_cores}VCPU-${floor(var.workernode_memory / 1024)}GB",
      zone : local.workernode_details[count.index].proxmox_node,
      region : var.proxmox_cluster_name,
    })
    file_name = "${local.workernode_details[count.index].name}-metadata.yaml"
  }
}

data "talos_machine_configuration" "workernode" {
  cluster_name     = var.kubernetes_cluster_name
  cluster_endpoint = "https://${var.controlplane_virtual_ip}:6443"

  machine_type    = "worker"
  machine_secrets = talos_machine_secrets.secrets.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

resource "talos_machine_configuration_apply" "workernode" {
  depends_on = [
    proxmox_virtual_environment_vm.workernode
  ]
  count    = var.workernode_num
  node     = [for ip in toset(flatten(proxmox_virtual_environment_vm.workernode.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix)][count.index]
  endpoint = [for ip in toset(flatten(proxmox_virtual_environment_vm.workernode.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix)][count.index]

  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.workernode.machine_configuration

  config_patches = [
    templatefile("configs/global.yaml", {
      dns_server = var.dns_server
    })
  ]
}
