---
title: Rock64 Kubernetes Cluster
parentcategory: "kubernetes"
category: rock64-k8s
description: |
  Rock64 (ARM64) Kubernetes Cluster information
---

# My Home Kubernetes Clusters

This page recounts the historical Rock64 cluster that existed from early 2019 to some time in 2023. In 2024 it was replaced by a [Raspberry Pi cluster][rpi-cluster].

## Rock64 Kubernetes Cluster

In early 2019 I built a three-node Kubernetes cluster on arm64 [Rock64 hardware](https://www.pine64.org/devices/single-board-computers/rock64/) (rev 2). The cluster itself was purchased from [PicoCluster](https://www.picocluster.com/collections/pico-3/products/pico-3-rock64). For more information about bootstrapping, refer to [Bootstrapping Rock64 Kubernetes Cluster](./bootstrap.html).

The cluster had one control-plane node and two worker nodes. Persistent storage was provided with Rook via Ceph doing some very unsavoury things to make it all work. Over time I would introduce NFS-based persistent storage from outside the cluster. In order to provide `LoadBalancer` capabilities, I used MetalLB.

Over time I added more nodes to the cluster: Some Raspberry Pi 4Bs and even an old x86_64 MacBook Pro. The cluster ran pi-hole and various other internal services, but there were some problems with the cluster.

The Rock64 hardware was pretty good, all things considered, but not quite as polished and reliable as the Raspberry Pi nodes. I wanted to add extra control-plane nodes, in a highly available configuration, to provide some extra stability. Unfortunately this didn't really work out very well. Ultimately, hardware failures spelled the doom of this cluster and it was retired.

## Raspberry Pi 4 Cluster

In the summer of 2024 I revisited my cluster because I missed the features of pi-hole and the other services my cluster provided and I wanted to rebuild the cluster again from the ground up, the right way.

I have notes on the [Raspberry Pi cluster](./raspi-k8s-cluster.html), including bootstrapping notes in another section.

## Rock64 Cluster Details

The cluster has three nodes: two workers, and one leader. [Storage](./bootstrap.html#persistent-storage) for the cluster is provided with [Rook](https://rook.io/) via [Ceph](https://ceph.com). I chose to use [MetalLB](https://metallb.universe.tf/) to provide ad-hoc load balancers for `Service`s running in the cluster.

## TektonCD-Pipeline

On March 12th, 2019, the [Google Open Source Blog](https://opensource.googleblog.com) [announced](https://opensource.googleblog.com/2019/03/introducing-continuous-delivery-foundation.html) the creation of the [Continuous Delivery Foundation](http://cd.foundation/), and that Google was contributing [tekton](https://github.com/tektoncd) to the CDF. Unfortunately, the [install procedure](https://github.com/tektoncd/pipeline/blob/c4168da54b7139913567ac0a473fee3316eb0487/docs/install.md) only supports amd64 architectures, which meant that it wouldn't run on my brand new arm64 cluster. I spent time successfully [porting the project to run on my arm64 hardware](./tektoncd-pipeline.html). In fact, the first build of `thedoh/musl-cross:1.1.20` was built with the pipeline in my cluster.

[rpi-cluster]: ./raspi-k8s-cluster.html