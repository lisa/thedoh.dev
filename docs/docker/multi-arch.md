---
title: Multi-Arch Container Images
parentcategory: "docker"
category: multi-arch
---

# Multi-Arch Container Images

One recurring theme I've run into while operating my [arm64 Kubernetes cluster](../kubernetes/rock64-cluster.html) is that most container images I want to use are built only for amd64 architectures. On an aarch64 (arm64) this is no good. I've had to go out of my way to [either recompile](../kubernetes/tektoncd-pipeline.html) or find alternately named images (eg `organization/image-arm64` vs `organization/image`). It would be so much easier if the referenced images in all these examples and docs worked with just using `organization/image`. 

## Images, A little background

[Under the hood](https://github.com/opencontainers/image-spec/blob/master/image-index.md) the architecture(s) in the images are a list of architectures supported by the image. When one of my arm64 Kubernetes cluster nodes makes a request to an image registry (such as [quay.io](https://quay.io)) it asks for an arm64 image. The container registry looks at the `organization/image` metadata see if it is in fact an arm64 image. When Kubernetes attempts to run the image I see the familiar error:

    standard_init_linux.go:207: exec user process caused "exec format error"

The image I want to run will not, because it doesn't contain any arm64 information and then I'm off to find an arm64 version, or to recompile/rebuild the image myself. It's a frustrating process, and when I wanted to write my own utility I wanted to be the change I wanted to see in the world and produce a multi-arch image.

# Homespun Utility

The utility is still in development (watch this space), but I'm doing early testing and from the start I want to create multi-arch artifacts so that my own cluster can pull the image as well as any amd64 cluster. I tried previously with the [docker-musl-cross](./docker-musl-cross.html) project by hand, but didn't really understand what was going on or why it worked. With this new utility I wanted to understand the inner workings of Docker's experimental [multi-platform images](https://blog.docker.com/2017/09/docker-official-images-now-multi-platform/).

## Making it Work With Docker Manifests

Docker implements the [Open Container Initiative (OCI) Image specification](https://github.com/opencontainers/image-spec/blob/master/spec.md)'s support for container images with multiple manifests (one manifest per architecture). The [documentation](https://docs.docker.com/engine/reference/commandline/manifest/) for Docker's `docker manifest` commands aren't documented the best, so I took the time to write a Makefile to enable reproducible artifacts.

In general, the steps to create the multi-arch container images is:

1. Enable docker's [experimental client features](https://docs.docker.com/engine/reference/commandline/cli/#configuration-files)
2. Build individual containers for all of your architectures (arm64, amd64, etc) and tag them with per-architecture identifiers
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
	rm -rf ~/.docker/manifests/$(shell echo $(REGISTRY)/$(IMG) | tr '/' '_')-$(VERSION) || true
```

The intended usage is `make VERSION=someversion clean docker-build docker-push`, which will first clean out each build artifact prior to re-building and running the `docker manifest push` command.

In this Makefile, the `docker-build` is delegating the creation of the architecture-specific images to the `docker build` command, which is taking the [`GOARCH`](https://golang.org/pkg/runtime/#pkg-constants) value as a [Docker build-time variable](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg). Different languages may have different requirements, but they will all likely make use of the architecture variable from the Makefile.

# Closing

As we move towards a heterogenus cloud it will be increasingly important to create build artifacts without the assumption that they will only run on amd64 architecture. With [rumours of Apple moving to Arm architecture](https://www.macrumors.com/2019/02/21/apple-custom-arm-based-chips-2020/), [cloud giant Amazon offering Arm instances](https://aws.amazon.com/about-aws/whats-new/2018/11/introducing-amazon-ec2-a1-instances/), (and hobbyists like yours truly) it isn't a certainty that the target of your images is a single architecture. Consider building multi-arch images for your containers.