
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
    }
    talos = {
      source  = "siderolabs/talos"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}