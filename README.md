# Homelab

- [Homelab](#homelab)
  - [Infasturcture details](#infasturcture-details)
    - [Bootstrap steps](#bootstrap-steps)
      - [First control plane node](#first-control-plane-node)
      - [Join Further Control Plane Nodes](#join-further-control-plane-nodes)
      - [Taint the control plane nodes to stop workloads running on them](#taint-the-control-plane-nodes-to-stop-workloads-running-on-them)
      - [Join Worker node(s)](#join-worker-nodes)
      - [Deploy ArgoCD](#deploy-argocd)
      - [Increase CoreDNS replicas to two](#increase-coredns-replicas-to-two)
    - [Kubernetes upgrades](#kubernetes-upgrades)

This repo holds the GitOps for my homelab Kubernetes cluster

## Infasturcture details

The cluster runs on a Proxmox cluster, mutiple Ubuntu VM's running [K3s](https://k3s.io/) 

I use [proxmox-csi-plugin](https://github.com/sergelogvinov/proxmox-csi-plugin) to provide block stoage to the cluster and because of this I use [proxmox-cloud-controller-manager](https://github.com/sergelogvinov/proxmox-cloud-controller-manager/) to label the nodes needed for the CSI plugin, because of this the cluster bootstrap is more complex than a normal K3s cluster because I need to disable the built in clould controller and provide a few extra labels.

### Bootstrap steps

#### First control plane node

1. Start the first control plane node:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - \
--cluster-init --token YOUR_JOIN_TOKEN --tls-san LOADBALANCER_IP \
--flannel-backend=none --disable-network-policy \
--disable=traefik \
--disable=servicelb \
--disable-cloud-controller \
--kubelet-arg="cloud-provider=external" \
--kubelet-arg="node-ip=NODE_IP" \
--kubelet-arg="provider-id=proxmox://homelab/VM_ID" \
--kubelet-arg="node-labels=proxmox-vmid=VM_ID"
```

And reterive the KUBECONFIG file

1. Remove the `node.cloudprovider.kubernetes.io/uninitialized=true:NoSchedule` taint - This would normally be done by the Cloud Controller Manager as part of labeling the nodes but we need to do it manually to get the Proxmox CCM running (We will reset this taint once the CCM is running)

```bash
kubectl taint node k3s-control-plane-1 node.cloudprovider.kubernetes.io/uninitialized=true:NoSchedule-
```

1. Deploy Cilium CNI

```bash
kubectl kustomize --enable-helm gitops/kube-system/cilium/ | kubectl apply -f -
```

At this point the one control plane node status should go to "Ready"

1. Deploy [External Secrets Operator](https://external-secrets.io/)  - I am using [Doppler](https://www.doppler.com/) to manage my secerts for my cluster and use Extenal Secrets to pull the secrets into the cluster

```bash
kubectl kustomize --enable-helm gitops/external-secrets/external-secrets/ | kubectl create -f -
# Apply the local secret containing the Doppler API token
kubectl apply -f secrets/doppler-api-token.yaml
```

1. Deploy [proxmox-cloud-controller-manager](https://github.com/sergelogvinov/proxmox-cloud-controller-manager/)

```bash
kubectl kustomize --enable-helm gitops/kube-system/proxmox-cloud-controller-manager/ | kubectl apply -f -
```

Reset the `node.cloudprovider.kubernetes.io/uninitialized=true:NoSchedule` taint on the node to force the CCM to fully label "k3s-control-plane-1"

```bash
kubectl taint node k3s-control-plane-1 node.cloudprovider.kubernetes.io/uninitialized:NoSchedule --overwrite
```

You should then see in the CCM logs the node will be fully labeled.

#### Join Further Control Plane Nodes

Join the other control plane nodes with the following command

#### Taint the control plane nodes to stop workloads running on them

Apply the taint `node-role.kubernetes.io/master:NoSchedule` to control plane nodes

```bash
kubectl taint node CONTROL_PLANE_NODE_NAME node-role.kubernetes.io/master:NoSchedule
```

There wwill have been workloads scheduled on the first control plane node while we were gettung the CCM working, Drain thie off the node

```bash
kubectl drain k3s-control-plane-1  --ignore-daemonsets --delete-emptydir-data
kubectl uncordon k3s-control-plane-1
```

#### Join Worker node(s)

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s agent \
--server https://192.168.3.50:6443 \
--token k3scluster \
--kubelet-arg="cloud-provider=external" \
--kubelet-arg="node-ip=VM_IP \
--kubelet-arg="provider-id=proxmox://homelab/VM_ID" \
--kubelet-arg="node-labels=proxmox-vmid=VM_ID"
```

#### Deploy ArgoCD

Now we have the base infrastructure in a good place  we can deploy argocd which will start applying changes from git rather than us applying changes locally

```bash
kubectl kustomize --enable-helm gitops/argocd/argocd/ | kubectl apply -f -
```

#### Increase CoreDNS replicas to two

This is done so that is still avaiable when doing node upgrades

```bash
kubectl edit deployments.apps -n kube-system coredns
```

Update `replicas` to 2

### Kubernetes upgrades

I use [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller) for upgrades.  

To trigger a upgrades update `server-plan.yaml` and `agent-plan.yaml` in `/gitops/system-upgrade/system-upgrade-controller/resources`  and set version to the required version of K3s and commit. Argo will sync and the controller wil spawn jobs to upgrade K3s
W