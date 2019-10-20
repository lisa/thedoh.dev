---
title: Multi-Arch Container Images
parentcategory: "docker"
category: multi-arch
description: |
  A discussion on how to build multi-architecture container images using Docker's "manifest" command, and why it is important to use these multi-arch images.
---

# Multi-Arch Container Images

One recurring theme I've run into while operating my [arm64 Kubernetes cluster](../kubernetes/rock64-cluster.html) is that most container images I want to use are built only for amd64 architectures. On an aarch64 (arm64) this is no good. I've had to go out of my way to [either recompile](../kubernetes/tektoncd-pipeline.html) or find alternately named images (eg `organization/image-arm64` vs `organization/image`). It would be so much easier if the referenced images in all these examples and docs worked with just using `organization/image`. 

## Container Image Background

When we talk about container images we have to remember that in reality they're fancy tarballs. That is, they're compressed files riding along next to descriptive metadata. Issuing a `docker pull organization/image` command will instruct your local Docker to communicate with the remote registry and it is at this point we meet our first multi-arch issue as it relates to image metadata.

### Walking Through `docker pull` (single manifest)

The following log snippet is from a `docker pull k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1` for the Kubernetes dashboard:

```
msg="Trying to pull k8s.gcr.io/kubernetes-dashboard-amd64 from https://k8s.gcr.io v2"
msg="Pulling ref from V2 registry: k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1"
msg="pulling blob \"sha256:9518d8afb433d5eede59f2b493fc14672649c218d919c2117c9d7ca6533c9832\""
msg="Downloaded 9518d8afb433 to tempfile /var/lib/docker/tmp/GetImageBlob239991869"
msg="Applying tar in /var/lib/docker/overlay2/a9a24a908c68566e4764879696aaff824ac7ab62971e9b2a92c54d6208cf0cbc/diff" storage-driver=overlay2
msg="Applied tar sha256:fbdfe08b001c6861c50073c98ed175d54e2d6440df7b797e52be97df0065098c to a9a24a908c68566e4764879696aaff824ac7ab62971e9b2a92c54d6208cf0cbc, size: 121711221"
```

To explain this: Docker has made a connection to the `k8s.gcr.io` image registry, found the manifest for the requested image, and downloaded the correct layer files (that means the tarball(s)). Nothing too exciting here, except for what is absent. Something different happens when the image has a [different kind of manifest](https://docs.docker.com/registry/spec/manifest-v2-2/) that supports multiple architectures.


### Walking Through `docker pull` (manifest list)

Here is another snippet from the [utility I'm writing](#homespun-utility) (see below):

```
msg="Trying to pull thedoh/validate-pihole-lists from https://registry-1.docker.io v2"
msg="Pulling ref from V2 registry: thedoh/validate-pihole-lists:19.06.3"
msg="docker.io/thedoh/validate-pihole-lists:19.06.3 resolved to a manifestList object with 2 entries; looking for a unknown/amd64 match"
msg="found match for linux/amd64 with media type application/vnd.docker.distribution.manifest.v2+json, digest sha256:c939074d45c08db307474944077dada2a504980d493a8226e2efdddb3a051710"
msg="pulling blob \"sha256:160404508aa17ac66e38832358c042347e233eae12ca52f629d205a6ede00c5e\""
...
```

The pull process starts off the same as before: Talk to Docker's image registry, get the manifests for the requested image and download the correct layer files. The difference here is the manifest for image is actually a [manifest list](https://github.com/opencontainers/image-spec/blob/master/image-index.md), one which contains an entry for `linux/amd64` and `linux/arm64`. In the snippet we see the `docker pull` negotiating for an `unknown/amd64` flavour, which it satisfies from the `linux/amd64` manifest entry. From the `linux/amd64` manifest entry, Docker is able to successfully download the appropriate layer files for the amd64 architecture.

## Using Public Images

Back on my arm64 Kubernetes cluster, I decide I want to run the [Kubernetes dashboard](https://github.com/kubernetes/dashboard/tree/89f56f09c41474c66ad7abbf2a39cd293015563b), to have that nice GUI, but when I follow the installation directions, to use [the recommended install manifest](https://github.com/kubernetes/dashboard/blob/89f56f09c41474c66ad7abbf2a39cd293015563b/aio/deploy/recommended/kubernetes-dashboard.yaml):

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

Wheat I end up with is:

    standard_init_linux.go:207: exec user process caused "exec format error"

Why? In this manifest is a reference to that `k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1` image, hardcoding the architecture. I want [the arm](https://github.com/kubernetes/dashboard/blob/89f56f09c41474c66ad7abbf2a39cd293015563b/aio/deploy/recommended/kubernetes-dashboard-arm.yaml) manifest, which, likewise hardcodes the _Arm_ architecture reference.

I don't mean to crap on the Kubernetes dashboard project at all. I'm certain there are reasons a mile long for the split manifests. The point is: I have an Arm cluster and wanted to join at the cool kids table by installing this add-on to what is likely the most popular container orchestration platform in history, only to find that the README doesn't make reference to Arm and the default is assumed to be amd64. What if I work at a large company and want to introduce Kubernetes to the team, except we work chose to build our cluster on [arm64 Amazon EC2 instances](https://aws.amazon.com/about-aws/whats-new/2018/11/introducing-amazon-ec2-a1-instances/) due to our deep internal knowledge of that architecture. It's an unfortunate look, and I think we can do better, especially because if there was one image to reference it clears up a lot of confusion down the line ("did we update it in all the places?" being the foremost).

# Homespun Utility

To be clear up front, the utility I'm writing isn't related at all to container images, or manifests, or even Kubernetes. All it's done so far is act as the catalyst for me to understand how these multi-arch containers work.

While doing development (watch this space) of the utility I want to create multi-arch artifacts from the start so that my own cluster can pull the image as well as any amd64 cluster. (I know from personal experience that retrofitting this kind of build infrastructure can be painful.) I tried previously with the [docker-musl-cross](./docker-musl-cross.html) project by hand, but didn't really understand what was going on or why it worked. With this new utility I wanted to understand the inner workings of Docker's experimental [multi-platform images](https://blog.docker.com/2017/09/docker-official-images-now-multi-platform/).

## Making it Work With Docker Manifest

As [mentioned previously](#walking-through-docker-pull-manifest-list), Docker is capable of creating container images with multiple manifests (one manifest per architecture). The [documentation](https://docs.docker.com/engine/reference/commandline/manifest/) for Docker's `docker manifest` commands aren't documented the best, so I took the time to write a Makefile to enable reproducible artifacts.

In general, the steps to create the multi-arch container images is:

1. Enable docker's [experimental client features](https://docs.docker.com/engine/reference/commandline/cli/#configuration-files)
2. Build individual images for all of your architectures (arm64, amd64, etc) and tag them with per-architecture identifiers
3. Create the manifest with `docker manifest create`
4. "Add" the individual, per-architecture images with `docker manifest annotate`.
5. Push the resulting multi-arch image to the image registry with `docker manifest push`

## The Makefile

I'm reproducing the `Makefile` for the project here. It's minimalistic but captures the above steps:

```Makefile
SHELL = bash -e
REVISION ?= 1
VERSION ?= 0.0.1
IMG := thedoh/somethingsoon
REGISTRY ?= docker.io
ARCHES ?= arm64 amd64

.PHONY: docker-build
docker-build:
	for a in $(ARCHES); do \
		docker build --build-arg=GOARCH=$$a -t $(IMG):$$a-$(VERSION) . ;\
		$(call set_image_arch,$(REGISTRY)/$(IMG):$$a-$(VERSION),$$a) ;\
		docker tag $(IMG):$$a-$(VERSION) $(IMG):$$a-latest ;\
	done

.PHONY: docker-multiarch
docker-multiarch: docker-build
	arches= ;\
	for a in $(ARCHES); do \
		arches="$$arches $(IMG):$$a-$(VERSION)" ;\
		docker push $(IMG):$$a-$(VERSION) ;\
	done ;\
	docker manifest create $(IMG):$(VERSION) $$arches  ;\
	for a in $(ARCHES); do \
		docker manifest annotate $(IMG):$(VERSION) $(IMG):$$a-$(VERSION) --os linux --arch $$a ;\
	done

.PHONY: docker-push
docker-push: docker-build docker-multiarch
	docker manifest push $(IMG):$(VERSION)

.PHONY: clean
clean:
	for a in $(ARCHES); do \
		docker rmi $(IMG):$$a-$(VERSION) || true ;\
		docker rmi $(IMG):$$a-latest || true ;\
	done ;\
	docker rmi $(IMG):latest || true ;\
	rm -rf ~/.docker/manifests/$(shell echo $(REGISTRY)/$(IMG) | tr '/' '_' | tr ':' '-')-$(VERSION) || true

# Set image Architecture in manifest and replace it in the local registry
# 1 image:tag
# 2 Set Architecture to
define set_image_arch
	cpwd=$$(pwd) ;\
	set -o errexit ;\
	set -o nounset ;\
	set -o pipefail ;\
	savedir=$$(mktemp -d) ;\
	chmod 700 $$savedir ;\
	mkdir -p $$savedir/change ;\
	docker save $(1) > $$savedir/image.tar ;\
	cd $$savedir/change ;\
	tar xf ../image.tar ;\
	jsonfile=$$(find $$savedir/change -name "*.json" -not -name manifest.json) ;\
	origarch=$$(cat $$jsonfile | jq -r .architecture) ;\
	if [[ $(2) != $$origarch ]]; then \
		docker rmi $(1) $(redirect) ;\
		echo "[set_image_arch] changing from $${origarch} to $(2) for $(1)" ;\
		sed -i -e "s,\"architecture\":\"$${origarch}\",\"architecture\":\"$(2)\"," $$jsonfile ;\
		tar cf - * | docker load $(redirect) ;\
		cd .. ;\
	fi ;\
	cd $$cpwd ;\
	\rm -rf -- $$savedir
endef
```

The intended usage is `make VERSION=someversion clean docker-build docker-push`, which will first clean out each build artifact prior to re-building and running the `docker manifest push` command.

In this Makefile, the `docker-build` is delegating the creation of the architecture-specific images to the `docker build` command, which is taking the [`GOARCH`](https://golang.org/pkg/runtime/#pkg-constants) value as a [Docker build-time variable](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg). Different languages may have different requirements, but they will all likely make use of the architecture variable from the Makefile.

# Closing

As we move towards a heterogenus cloud it will be increasingly important to create build artifacts without the assumption that they will only run on amd64 architecture. With [rumours of Apple moving to Arm architecture](https://www.macrumors.com/2019/02/21/apple-custom-arm-based-chips-2020/), [cloud giant Amazon offering Arm instances](https://aws.amazon.com/about-aws/whats-new/2018/11/introducing-amazon-ec2-a1-instances/), (and hobbyists like yours truly) it isn't a certainty that the target of your images is a single architecture. Consider building multi-arch images for your containers.
