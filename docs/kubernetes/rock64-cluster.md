---
title: Rock64 Kubernetes Cluster
parentcategory: "kubernetes"
category: rock64-k8s
description: |
  Rock64 (ARM64) Kubernetes Cluster information
---

# Rock64 Kubernetes Cluster

In early 2019 I built a three-node Kubernetes cluster on arm64 [Rock64 hardware](https://www.pine64.org/?page_id=7147). The cluster itself was purchased from [PicoCluster](https://www.picocluster.com/collections/pico-3/products/pico-3-rock64). For more information about bootstrapping, refer to [Bootstrapping Rock64 Kubernetes Cluster](./bootstrap.html).

## Cluster Details

The cluster has three nodes: two workers, and one leader. The leader node provides persistent volumes to compute nodes via [NFS](./bootstrap.html#persistent-storage). I chose to use [MetalLB](https://metallb.universe.tf/) to provide ad-hoc load balancers for `Service`s running in the cluster.

## TektonCD-Pipeline

On March 12th, 2019, the [Google Open Source Blog](https://opensource.googleblog.com) [announced](https://opensource.googleblog.com/2019/03/introducing-continuous-delivery-foundation.html) the creation of the [Continuous Delivery Foundation](http://cd.foundation/), and that Google was contributing [tekton](https://github.com/tektoncd) to the CDF. Unfortunately, the [install procedure](https://github.com/tektoncd/pipeline/blob/c4168da54b7139913567ac0a473fee3316eb0487/docs/install.md) only supports amd64 architectures, which meant that it wouldn't run on my brand new arm64 cluster. I spent time successfully [porting the project to run on my arm64 hardware](./tektoncd-pipeline.html). In fact, the first build of `thedoh/musl-cross:1.1.20` was built with the pipeline in my cluster.