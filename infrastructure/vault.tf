provider "vault" {
    address = var.vault_uri
}

resource "vault_auth_backend" "kubernetes" {
  count = var.vault_uri != "" ? 1 : 0
  type = "kubernetes"
  path = "kubernetes-${var.kubernetes_cluster_name}"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  count = var.vault_uri != "" ? 1 : 0

  depends_on = [ 
    talos_machine_bootstrap.bootstrap
   ]

  backend                = vault_auth_backend.kubernetes[0].path
  kubernetes_host        = "http://${var.vault_uri}"
  kubernetes_ca_cert     = base64decode(talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.ca_certificate)
  issuer                 = "api"
  disable_iss_validation = "true"
}