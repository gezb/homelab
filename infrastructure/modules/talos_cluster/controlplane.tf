locals {
  controlplane_details = flatten([
    [
      for i in range(var.controlplane_num) :
      {
        id           = "${var.vm_id_prefix}${var.controlplane_host_id_prefix}${i + 1}"
        name         = "${var.controlplane_hostname_prefix}-${i + 1}"
        proxmox_node = element(var.controlplane_proxmox_nodes, i)
        ipv4         = "${var.network_id_prefix}.${var.controlplane_host_id_prefix}${i + 1}/24"
      }
    ]
  ])
}

resource "proxmox_virtual_environment_vm" "controlplane" {
  count = var.controlplane_num
  vm_id = local.controlplane_details[count.index].id

  pool_id   = proxmox_virtual_environment_pool.proxmox_resource_pool.id
  node_name = local.controlplane_details[count.index].proxmox_node

  name        = local.controlplane_details[count.index].name
  description = local.controlplane_details[count.index].name
  tags        = var.controlplane_tags

  mac_addresses =  var.network_dhcp ? [ var.network_dhcp_mac_addresses[count.index] ] : []

  cpu {
    cores = var.controlplane_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.controlplane_memory
  }

  network_device {
    bridge = var.controlplane_network_device
    mac_address = var.network_dhcp ? var.network_dhcp_mac_addresses[count.index] : ""
  }

  initialization {
    datastore_id = var.controlplane_datastore
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
          address = local.controlplane_details[count.index].ipv4
          gateway = var.controlplane_gateway
        }
      }
    }
    meta_data_file_id = proxmox_virtual_environment_file.controlplane_metadata[count.index].id
  }

  disk {
    datastore_id = var.controlplane_datastore
    file_id      = proxmox_virtual_environment_file.talos_image.id
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.controlplane_disk_size
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

}


# This metadata is used by Talos to set node labels 
# These are needed for the Proxmox CSI driver, see https://github.com/sergelogvinov/proxmox-csi-plugin
resource "proxmox_virtual_environment_file" "controlplane_metadata" {
  count        = var.controlplane_num
  node_name    = local.controlplane_details[count.index].proxmox_node
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_datastore
  source_raw {
    data = templatefile("${path.module}/configs/metadata.yaml", {
      hostname : local.controlplane_details[count.index].name,
      id : local.controlplane_details[count.index].id,
      providerID : "proxmox://homelab/${local.controlplane_details[count.index].proxmox_node}",
      type : "${var.controlplane_cpu_cores}VCPU-${floor(var.controlplane_memory / 1024)}GB",
      zone : local.controlplane_details[count.index].proxmox_node
      region : var.proxmox_cluster_name,
    })
    file_name = "${local.controlplane_details[count.index].name}-metadata.yaml"
  }
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.kubernetes_cluster_name
  cluster_endpoint = "https://${[for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip][0]}:6443"

  machine_type    = "controlplane"
  machine_secrets = talos_machine_secrets.secrets.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [
    proxmox_virtual_environment_vm.controlplane
  ]

  count    = var.controlplane_num
  node     = [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip][count.index]
  endpoint = [for ip in toset(flatten(proxmox_virtual_environment_vm.controlplane.*.ipv4_addresses)) : ip if startswith(ip, var.network_id_prefix) && ip != var.controlplane_virtual_ip][count.index]

  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  config_patches = [
    templatefile("${path.module}/configs/global.yaml", {
      dns_server = var.dns_server
    }),
    templatefile("${path.module}/configs/controlplane.yaml", {
      dns_server = var.dns_server
      talos_virtual_ip = var.controlplane_virtual_ip
    }),
    var.argocd_enabled ? templatefile("${path.module}/configs/argocd.yaml", {
      argocdmanifest = var.argocd_install_manifest
      argocdrepo     = var.argocd_repo
      argocdprojectpath = var.argocd_project_path
    }) : null,
    var.allow_scheduling_on_control_plane ? templatefile("${path.module}/configs/allowschedulingoncontrolplanes.yaml", {}) : null,
  ]
}
