---
title: Raspberry Pi 4 Kubernetes Cluster
parentcategory: "kubernetes"
category: raspi-k8s
description: |
  Raspberry Pi 4B (ARM64) Kubernetes Cluster information, including bootstrap notes.
---

# My Raspberry Pi Home Kubernetes Cluster

## Prologue

In early 2019 I (built a three-node Kubernetes cluster)[./rock64-cluster.html] based on Rock64 single board computers. It had one control-plane node and two worker nodes. As is often the case, the scope of the cluster grew to include a few more nodes. These nodes were a small number of Raspberry Pi 4Bs and an old x86_64 MacBook Pro. As the cluster grew, I wanted to add extra control-plane nodes to add redundancy to the somewhat flakey Rock64 node.

It turns out, however, that adding extra control-plane nodes to an existing cluster that wasn't already set up for it at the start is quite hard.

Over time, the cluster became more and more unstable until one day it simply stopped working entirely.

## Cluster Reborn

I was lucky enough to pick up some additional Raspberry Pi 4Bs during the supply slump and these were destined to join the three former cluster nodes in forming a six node cluster Raspberry Pi 4, with three control-plane nodes and three worker nodes.

In the summer of 2024 that setup began.

The cluster begins life as Kubernetes v1.30.3 with [kube-vip][kube-vip] providing the API server's [VIP][wiki-vip]. Kube-vip will also provide IP allocation for `LoadBalancer`-type `Service` objects.

Persistent storage will be provided via NFS by a server outside of the cluster, with future plans to augment this for reasons I'll explain later.

## Naming Scheme

The naming scheme for nodes in the cluster are as follows. Naming things is one of the hardest problems in computer science and so I did not want to overcomplicate things here.

* kube-cp1
* kube-cp2
* kube-cp3
* kube-w1
* kube-w2
* kube-w3

## Bootstrapping

### Node Preparation

Each node must have an operating system and for that I'm using the Raspberry Pi Imager, choosing the Raspberry Pi Lite (64 bit) image. This is based on Debian (Bookworm 12.6) I'm joining to the wireless network (Did I forget to mention they're all connected via wifi?) and setting hostname along the way.

I have to enable the memory cgroup, which is easy to do:

```shell
echo " cgroup_enable=memory cgroup_memory=1" >> /boot/firmware/cmdline.txt
```

The kubelet will refuse to run with swap enabled, and so it must be permanently disabled:

```shell
systemctl mask swap.target
systemctl mask var-swap.swap
systemctl mask dphys-swapfile.service
```

Next, I need to make sure the system is up to date. I take this opportunity to install vim and NFS packages (See the [Persistent NFS Storage](#persistent-nfs-storage) section for more on that). There will be more package installations to come.

```shell
apt update && \
apt upgrade -y && \
apt install -y vim portmap nfs-common
```

Next, I need to make sure IP forwarding is enabled:

```shell
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

This is a good time to reboot the node. Once the node reboots it will be time to install the Kubernetes packages and containerd:

```shell
apt install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update -y
apt install containerd -y

cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay && modprobe br_netfilter
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# get the config.toml for containerd from my private gist (ooh, dank leaks)
mkdir -p /etc/containerd && cd /etc/containerd
curl -LO https://gist.github.com/lisa/1cadf8234e6516fbdd0aaf594f3dd948/raw/4930d087df36b1ed2f326b1fdfa18c10b0468128/config.toml
cd $OLDPWD
systemctl enable --now containerd
```

Refer to the [DNS](#dns) section for more discussion on this, but I will populate `/etc/hosts` with the addressing of each node:

```shell
echo "192.168.0.10 kube-cp1" >> /etc/hosts
echo "192.168.0.11 kube-cp2" >> /etc/hosts
echo "192.168.0.12 kube-cp3" >> /etc/hosts
echo "192.168.0.13 kube-w1" >> /etc/hosts
echo "192.168.0.14 kube-w2" >> /etc/hosts
echo "192.168.0.15 kube-w2" >> /etc/hosts
```

Finally, and once the Kubernetes packages are installed on each node, the cluster can begin to take shape with [the first node](#the-first-node):

```shell
# apt already knows where to get this from containerd
apt install -y kubelet kubeadm kubectl && \
apt-mark hold kubelet kubeadm kubectl
```

### DNS

Prior to the bootstrapping process, I had to make a decision on DNS. On one hand, having the addressing in DNS means I don't have to worry about it, but if DNS is unreliable then the cluster can't really do anything. But if I put the records into `/etc/hosts`, it's as reliable as the local filesystem but hard to scale and manage. I split the difference and put the `kube-vip` address into DNS and everything else in `/etc/hosts`. The cluster nodes will communicate with the API server through that address. Other clients (such as me on my computer) will also access the cluster through that same `kube-vip` address.

### The First Node

Once all [the initial node preparation is done](#node-preparation), the first thing to do is drop in the [kube-vip configuration][kube-vip-static-install-docs] that I created before. There's no need to create this every time. I put it in a private gist to save time. Due to a [kube-vip bug][superadmin-bug], I have to change the first the manifest to use the superadmin credentials. Once the cluster is boostrapped, this can (and will) be undone.

```shell
curl --create-dirs -o /etc/kubernetes/manifests/kube-vip.yaml https://gist.githubusercontent.com/lisa/af31aa595f6f32fe42494c3f22327011/raw/718a5f0721717b1030a4304880c52c158d7e4bfd/kube-vip.yaml
# For bootstrapping kube-vip (See https://github.com/kube-vip/kube-vip/issues/684)
# undo this after installation
sed -i 's#path: /etc/kubernetes/admin.conf#path: /etc/kubernetes/super-admin.conf#' \
          /etc/kubernetes/manifests/kube-vip.yaml
```

Now it's time to get `kubeadm` setting up the cluster:

```shell
kubeadm init --control-plane-endpoint "kube-vip.example.com:6443" --upload-certs --pod-network-cidr=10.244.0.0/16
# lots of output...
# ...
```

With success, other the two other control-plane nodes can be joined to the cluster.

### Join the Other Control Plane Nodes

The `kubeadm init` command used in the [first control plane](#the-first-node) can be used here now _after_ the kube-vip config is put into place:

```shell
curl --create-dirs -o /etc/kubernetes/manifests/kube-vip.yaml https://gist.githubusercontent.com/lisa/af31aa595f6f32fe42494c3f22327011/raw/718a5f0721717b1030a4304880c52c158d7e4bfd/kube-vip.yaml
 
kubeadm join kube-vip.example.com:6443 --token the.token \
--discovery-token-ca-cert-hash sha256:discovery-token-ca-cert-hash \
--control-plane --certificate-key control-plane-cert-key
```

And with the final node joined, it's time to do the final [cluster control-plane bootstrapping](#finishing-the-cluster-bootstrapping).

### Finishing the Cluster Bootstrapping

Finally, after all three control-plane nodes are present in the cluster, wrap it up:

* Install Flannel pod network
* Add kube-vip RBAC rules
* Configure kube-vip's `LoadBalancer` address range via `ConfigMap`
* Install kube-vip cloud-controller
* Reset kube-vip's static pod on kube-cp1 back to using the normal admin credentials.

```shell
kubectl apply -f https://github.com/flannel-io/flannel/releases/download/v0.25.5/kube-flannel.yml
kubectl apply -f https://github.com/kube-vip/website/blob/4e6667beb05b40c0e6a5b60f26e309b5f8bdd709/content/manifests/rbac.yaml
kubectl -n kube-system delete cm kubevip; kubectl create configmap -n kube-system kubevip --from-literal range-global=192.168.0.100-192.168.0.120
kubectl apply -f https://github.com/kube-vip/kube-vip-cloud-provider/blob/9e13c0a82a61c229bd1da17b2cbf60957a46aa56/manifest/kube-vip-cloud-controller.yaml
# Revert kube-vip.yaml to normal admin.conf with:
sed -i 's#path: /etc/kubernetes/super-admin.conf#path: /etc/kubernetes/admin.conf#' \
          /etc/kubernetes/manifests/kube-vip.yaml
```

### Add Worker Nodes

There's not much else to do at this point but add all the worker nodes:

```shell
kubeadm join kube-vip.example.com:6443 --token the.token --discovery-token-ca-cert-hash sha256:discovery-token-ca-cert-hash
```

If it's been some time since the [initial `kubeadm`](#the-first-node), the join token can be regenerated:

```shell
kubeadm token create --print-join-command
```

The cluster is complete! Storage is another matter.

## Persistent NFS Storage

The [NFS Subdir External Provisioner][nfs-subdir-ext-provisioner] knows how to handle the lifecycle of persistent volumes in Kubernetes with NFS. Setting up a server to provide the NFS storage itself is outside the scope of this document, and is left as an exercise to the reader. I'm using the [v4.0.15][nfs-subdir-ext-provisioner-v4.0.15] tag.

It's really as easy as cloning the [Git repository][nfs-subdir-ext-provisioner] and applying the manifests:

```shell
git clone https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner.git
cd nfs-subdir-external-provisioner
kubectl create ns nfs-provisioner
# change the namespace to one of my choosing
gsed -i'' "s/namespace:.*/namespace: nfs-provisioner/g" ./deploy/rbac.yaml ./deploy/deployment.yaml
```

Then, edit the `StorageClass` file to tell the provisioner some details about the lifecycle:

```yaml
# deploy/class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "true"
  onDelete: "retain"
reclaimPolicy: "Retain"
```

Finally, edit the `Deployment` file to use the address of your NFS server:

```yaml
# deploy/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: nfs-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              value: 192.168.0.67
            - name: NFS_PATH
              value: /nfs-k8s
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.0.67
            path: /nfs-k8s
```

And then apply:

```shell
kubectl create -f deploy/rbac.yaml
kubectl create -f deploy/deployment.yaml
kubectl create -f deploy/class.yaml
```

Now, `PersistentVolumeClaims` can be created using the `nfs-storage` `StorageClass`.

### Prometheus And its NFS Woes

Prometheus does not like to use NFS. From the [Prometheus storage documentation][prometheus-storage]

> **CAUTION**: Non-POSIX compliant filesystems are not supported for Prometheus' local storage as unrecoverable corruptions may happen. NFS filesystems (including AWS's EFS) are not supported. NFS could be POSIX-compliant, but most implementations are not. It is strongly recommended to use a local filesystem for reliability.

While I do have Prometheus deployed to my cluster, I also have it provisioned on NFS, which means that it gets cranky. I'll look into some other option for it in the future, if I should ever put "mission critical" data into Prometheus. For now, I'm content to let it whine.

[kube-vip]: https://kube-vip.io
[wiki-vip]: https://en.wikipedia.org/wiki/Virtual_IP_address
[kube-vip-static-install-docs]: https://kube-vip.io/docs/installation/static/#generating-a-manifest
[superadmin-bug]: https://github.com/kube-vip/kube-vip/issues/684
[nfs-subdir-ext-provisioner]: https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
[nfs-subdir-ext-provisioner-v4.0.15]: https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/tree/nfs-subdir-external-provisioner-4.0.15
[prometheus-storage]: https://prometheus.io/docs/prometheus/latest/storage/