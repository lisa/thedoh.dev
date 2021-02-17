---
title: Looping Back Ceph
parentcategory: "kubernetes"
category: rock64-k8s
description: |
  Sometimes you need to trick Ceph into working
---

# Looping Back Ceph

One of the ideas I wanted to experiment with with my [Rock 64 cluster](rock64-cluster.md) is [Ceph](https://ceph.io/ceph-storage/) and [Rook](https://rook.io). Ceph is used for (network) distributed storage, and Rook is a Kubernetes-native way to make your Ceph-based storage available to a Kubernetes cluster.

Prior to setting up my little cluster I had never used either product before and really had no idea what I was getting myself into, or what the requirements of the two were. Well, I knew Rook worked with Ceph, but I didn't know what Ceph needed to work.

# Cluster Storage

My cluster only has on-board storage coming from the SD card I have installed on each device. Each card is 64GB in size, so it's pretty big for an embedded device, but I have no other storage. This meant that everything needed to come from that.

By the time I got around to Ceph, I had already finalized the partition scheme, and there were no extra partitions free on the cards. This was a quirk of the utility I used to prepare the partition scheme.

# Ceph Requirements

Once I had the cluster up and running with local storage it was time to get Ceph working, and so I set to it.

I quickly learned that Ceph needs block devices to work and that meant I was in a bind because of the [storage situation](#cluster-storage). How could I force Ceph to do it?

## Loopback

Linux has the concept of a loopback device (or loop device). This pseudofilesystem allows users to mount files to appear as a particular device. For example, a CD image might appear as a `.iso` file, and its contents normally inaccessible, but with this pseudofilesystem, the Linux kernel can mount the file and expose its contents (`mount -o loop /path/to/iso /mnt/cdimage` for example).

I thought that if I could create a chunk of space on disk that I could use it for Ceph (`dd if=/dev/zero of=/cephstorage bs=1M count=1024` for 1GB, and using `losetup(8)`). It turns out that Ceph is smart enough to not allow anything from `/dev/loop*` to be used for storage.

What if I could create some kind of _logical_ block device to use for Ceph, based on this `losetup(8)` idea?

## Logical Volume Management

Logical Volume Management, or LVM2 as it is better known on Linux, is a way to define storage volumes in a logical manner instead of a more fixed way with a partition table. The way it work on Linux is a block device is nominated to be a Physical Volume (PV). From the PV the administrator creates a Volume Group (VG) to serve as the general pool of storage available for logical volumes. Finally, Logical Volumes (LV) are created from the VG's pool of storage. For each LV, a block device is exposed in `/dev` (at various locations, depending on system configuration).

The key takeaway here is that these are honest to goodness block devices, and Ceph will happily allow their use.

# Conclusion

I'm not saying I'm a saint here, alright. I'm using an SD card to back a cluster's distributed storage. For those playing along at home, this is the amount of indirection:


```
SD Card
  |
  \-> Partition Table
      |
      \-> Linux filesystem
          |
          \-> Loopback mount
              |
              \-> PV/VG/Logical Volume
                  |
                  \-> Ceph
```

I would not describe myself as very knowledgable about Ceph whatsoever. I know just enough to be dangerous (as one can see) and to connect the dots and barely get Rook working in my cluster.

I can't recommend others do this, and for all I know, it's now entirely unsupported, as the version on my cluster is an older version `12.2.12`.

As a hobbyist I can say that it was fun to hack my way around the limitations I faced, and it was certainly gratifying to make work. Do not try this at work!
