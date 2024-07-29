
# Proxmox
variable "proxmox_hostname" {
  type        = string
  description = "IP address or hostname of the Proxmox server"
}

# Proxmox won't let you upload a xz archive as a disk image. So trick it by saving the file as *.iso.
# Afterwards, use a remote-exec provisioner to name it back to *.xz and, finally, extract it. 
# This SSH key must be able to log in as root to the proxmox node, without passphrase
variable "proxmox_ssh_hostname" {
  type        = string
  description = "Hostname/IP to use to SSH  to the Proxmox server"
}
variable "proxmox_ssh_key_path" {
  type        = string
  description = "Path to an SSH key used to connect to the Proxmox server"
}

variable "proxmox_snippets_datastore" {
  type        = string
  description = "The datastore to store the node metadata snippet used to derive node labels"
  default     = "local"
}

variable "dns_server" {
  type        = string
  default = "8.8.8.8"
  description = "DNS server to use for all nodes"
}

variable "vm_id_prefix" {
  description = "Prefix to be appended to the Proxmox VM ID"
  type = string
  default = ""
}

variable "network_id_prefix" {
  description = "The network ID to be used if DHCP is disabled(the first three numbers of the IP address)"
  type        = string
}



variable "controlplane_virtual_ip" {
  type        = string
  description = "Virtual IP address you wish for Talos to use for the control plane."
}

variable "argocd_enabled" {
  type        = bool
  description = "If ArgoCD Should be bootstrapped as part of cluster creation"
  default     = false
}

variable "argocd_install_manifest" {
  type        = string
  description = "The URL of the yaml to use to install argo (needs to specify argocd namespace as part of each resources metadata)"
  default     = ""
}
variable "argocd_repo" {
  type        = string
  description = "The Git Repo that should be used to boostrap the cluster"
  default     = ""
}

variable "argocd_project_path" {
  type = string
  description = "The subpath in the git repo that should be used to bootstap the cluster"
  default = ""
}

variable "vault_uri" {
  type = string
  description = "The URL of the Vault instance to configure kuberntes auth on."
  default = ""
}