# IAC and Gitops for my k8s cluster run by Talos Linux

Still very much WIP at this point...

The cluster that gets stood up is not publicly accessisble - Access to services is either on the local LAN or via [Tailscale](https://tailscale.com/)

## Cluster Creation

The terraform provided in the `infrastructure` bootstraps a [Talos](https://www.talos.dev/) Kurbernetes cluster using terraform and optionally installs ArgoCD and bootstraps it using the repo specifed
