locals {
  controlplane_details= flatten([
    [
      for i in range(var.controlplane_num) :
      {
        id           = "${var.controlplane_prefix}${i + 1}"
        name         = "${var.controlplane_hostname_prefix}-${i + 1}"
        proxmox_node = i % 2 == 0 ? "proxmox2" : "proxmox3"
        ip           = "192.168.1.${var.controlplane_prefix}${i + 1}"
        ipv4         = "192.168.1.${var.controlplane_prefix}${i + 1}/24"

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

  cpu {
    cores = var.controlplane_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.controlplane_memory
  }

  network_device {
    bridge = var.controlplane_network_device
  }

  initialization {
    datastore_id = var.controlplane_datastore
    ip_config {
      ipv4 {
        address = local.controlplane_details[count.index].ipv4
        gateway = var.controlplane_gateway
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
    # If left to default, Terraform will be held for 15 minutes waiting for the agent to start
    # before it is even installed. Prevent this by effectively immediatly timing out.
    timeout = "1s"
  }

  operating_system {
    type = "l26"
  }

}

resource "proxmox_virtual_environment_file" "controlplane_metadata" {
  count        = var.controlplane_num
  node_name    = count.index % 2 == 0 ? "proxmox2" : "proxmox3"
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
  cluster_name = var.kubernetes_cluster_name
  cluster_endpoint = "https://192.168.1.${var.controlplane_prefix}1:6443"

  machine_type    = "controlplane"
  machine_secrets = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [
    proxmox_virtual_environment_vm.controlplane
  ]

  count    = var.controlplane_num
  node     = local.controlplane_details[count.index].ip
  endpoint = local.controlplane_details[count.index].ip

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  config_patches = [
    templatefile("configs/global.yaml", {
      proxmox_host =  local.controlplane_details[count.index].proxmox_node
    }),
    templatefile("configs/controlplane.yaml", {
      talos_virtual_ip = var.talos_virtual_ip
      clusters = yamlencode({
        clusters = [
          {
            token_id     = var.proxmox_csi_token_id
            token_secret = var.proxmox_csi_token_secret
            url          = "http://${var.proxmox_hostname}:8006/api2/json"
            insecure     = true
            region       = var.proxmox_cluster_name
          },
        ]
      })
    }),
    var.argocd_enabled ? templatefile("configs/argocd.yaml", {
      argocdmanifest = var.argocd_install_manifest
      argocdrepo = var.argocd_repo
    }) : null,

  ]
}
