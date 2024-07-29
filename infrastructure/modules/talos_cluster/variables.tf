
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

variable "proxmox_cluster_name" {
  type        = string
  description = "The the Proxmox cluster name"
  default     = "proxmox"
}


# Talos Image
variable "talos_version" {
  type        = string
  description = "Identify here: https://github.com/siderolabs/talos/releases"
}
variable "talos_image_factory_schematic_id" {
  type    = string
  default = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515" #  QEumu Guest Addons
}

# Kubernetes Cluster
variable "kubernetes_version" {
  type        = string
  description = "Identify here: https://github.com/siderolabs/kubelet/pkgs/container/kubelet"
}
variable "kubernetes_cluster_name" {
  type        = string
  description = "Kubernetes cluster name you wish for Talos to use"
  default     = "homelab"
}

variable "allow_scheduling_on_control_plane" {
  type        = bool
  description = "Allow Workloads to run on contol plane nodes"
  default     = false

}

variable "dns_server" {
  default     = "8.8.8.8"
  type        = string
  description = "DNS server to use for all nodes"
}
variable "network_dhcp" {
  description = "If DHCP should be used to aquire IP adresses(not tested)"
  type        = bool
  default     = false
}

# e.g.  "bc:24:11:db:46:01", "bc:24:11:db:46:02", "bc:24:11:db:46:03", "bc:24:11:db:46:04", "bc:24:11:db:46:05" 
variable "network_dhcp_mac_addresses" {
  type        = list(string)
  description = "List of mac addresses that have had static IPs reserved on the router/DHCP server"
  default     = []
}

variable "vm_id_prefix" {
  description = "Prefix to be appended to the Proxmox VM ID"
  type        = string
  default     = ""
}

variable "network_id_prefix" {
  description = "The network ID to be used if DHCP is disabled(the first three numbers of the IP address)"
  type        = string
}



variable "controlplane_virtual_ip" {
  type        = string
  description = "Virtual IP address you wish for Talos to use for the control plane."
}
variable "controlplane_num" {
  type        = number
  description = "Quantity of controlplane nodes to provision"
}
variable "controlplane_proxmox_nodes" {
  type        = list(string)
  description = "The Proxmox nodes that should be used to run control plane nodes."
}
variable "controlplane_host_id_prefix" {
  description = "IP address prefix (less the last digit) of the Control Plane nodes"
  type        = string
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
  description = "Quantity of workernode nodes to provision"
}
variable "workernode_proxmox_nodes" {
  type        = list(string)
  description = "The Proxmox nodes that should be used to run control plane nodes."
}
variable "workernode_host_id_prefix" {
  description = "IP address prefix (less the last digit) of the Worker nodes"
  type        = string
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
