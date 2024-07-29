
# Proxmox
variable "proxmox_hostname" {
  type        = string
  description = "IP address or hostname of the Proxmox server"
}
variable "proxmox_ssh_key_path" {
  type        = string
  description = "Path to an SSH key used to connect to the Proxmox server"
}
variable "proxmox_snippets_datastore" {
  type = string
  description = "The datastore to store me node metadata snippet"
  default = "local"
}
variable "proxmox_cluster_name" {
  type = string
  description = "The the Proxmox cluster name"
  default = "homelab"
}


# Talos Image
variable "talos_image_factory_schematic_id" {
  type = string
  default = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515" #  QEumu Guest Addons
}

# Kubernetes Cluster
variable "talos_version" {
  type        = string
  description = "Identify here: https://github.com/siderolabs/talos/releases"
}
variable "kubernetes_version" {
  type        = string
  description = "Identify here: https://github.com/siderolabs/kubelet/pkgs/container/kubelet"
}
variable "kubernetes_cluster_name" {
  type        = string
  default     = "Homelab"
  description = "Kubernetes cluster name you wish for Talos to use"
}

variable "talos_virtual_ip" {
  type        = string
  description = "Virtual IP address you wish for Talos to use"
}

variable "controlplane_num" {
  type        = number
  default     = 3
  description = "Quantity of controlplane nodes to provision"
}
variable "controlplane_prefix" {
  type        = string
  description = "IP address prefix (less the last digit) of the Worker Nodes"
}
variable "controlplane_hostname_prefix" {
  type        = string
  default     = "k8s-controlplane"
  description = "Hostname prefix (less the last digit) of the controlplane nodes"
}
variable "controlplane_tags" {
  type        = list(string)
  default     = []
  description = "Tags to apply to the controlplane virtual machines"
}
variable "controlplane_cpu_cores" {
  type        = number
  default     = 2
  description = "Quantity of CPU cores to apply to the controlplane virtual machines"
}
variable "controlplane_memory" {
  type        = number
  default     = 4096
  description = "Quantity of memory (megabytes) to apply to the controlplane virtual machines"
}
variable "controlplane_datastore" {
  type        = string
  description = "Datastore used for the controlplane virtual machines"
}
variable "controlplane_disk_size" {
  type        = string
  default     = "50"
  description = "Quantity of disk space (gigabytes) to apply to the controlplane virtual machines"
}
variable "controlplane_network_device" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the controlplane virtual machines"
}
variable "controlplane_gateway" {
  type        = string
  description = "Network device used for the workernode virtual machines"
}

# Worker Nodes
variable "workernode_num" {
  type        = number
  default     = 2
  description = "Quantity of workernode nodes to provision"
}
variable "workernode_prefix" {
  type        = string
  description = "IP address prefix (less the last digit) of the Worker Nodes"
}

variable "workernode_hostname_prefix" {
  type        = string
  default     = "k8s-worker"
  description = "Hostname prefix (less the last digit) of the workernode nodes"
}
variable "workernode_tags" {
  type        = list(string)
  default     = []
  description = "Tags to apply to the workernode virtual machines"
}
variable "workernode_cpu_cores" {
  type        = number
  default     = 2
  description = "Quantity of CPU cores to apply to the workernode virtual machines"
}
variable "workernode_memory" {
  type        = number
  default     = 8192
  description = "Quantity of memory (megabytes) to apply to the workernode virtual machines"
}
variable "workernode_datastore" {
  type        = string
  description = "Datastore used for the workernode virtual machines"
}
variable "workernode_disk_size" {
  # Talos recommends 100Gb
  type        = string
  default     = "50"
  description = "Quantity of disk space (gigabytes) to apply to the workernode virtual machines"
}
variable "workernode_network_device" {
  type        = string
  default     = "vmbr0"
  description = "Network device used for the workernode virtual machines"
}
variable "workernode_gateway" {
  type        = string
  description = "Network device used for the workernode virtual machines"
}


# CSI Controller
variable "proxmox_csi_token_id" {
  type = string
  description = "The Proxmox token id to be used for the Proxmox CSI driver, see https://github.com/sergelogvinov/proxmox-csi-plugin"  
  default =  "kubernetes-csi@pve!csi"
}

variable "proxmox_csi_token_secret" {
  type = string
  description = "The Proxmox token secret to be used for the Proxmox CSI driver, see https://github.com/sergelogvinov/proxmox-csi-plugin"  
}

variable "argocd_enabled" {
  type = bool
  description = "If ArgoCD Should be bootstrapped as part of cluster creation"
  default = false
}

variable "argocd_install_manifest" {
  type = string
  description = "The URL of the yaml to use to install argo (needs to specify argocd namespace as part of each resources metadata)"
  default = ""
}
variable "argocd_repo" {
  type = string
  description = "The Git Repo that should be used to boostrap the cluster"
  default = ""
}