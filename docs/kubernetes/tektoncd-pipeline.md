---
title: Porting tektoncd/pipeline to arm64
parentcategory: "kubernetes"
category: rock64-k8s
---


# Background

As [mentioned](./rock64-cluster.html#tektoncd-pipeline), upon [announcement](https://opensource.googleblog.com/2019/03/introducing-continuous-delivery-foundation.html), the [tektoncd/pipeline](https://github.com/tektoncd/pipeline/) project only targeted amd64 hardware, as I quickly learned.

I wanted to try this new continuous delivery project out since I wanted to target [musl-cross](/docker/docker-musl-cross.html) for arm64, and if I could run that build locally on native hardware from within my Kubernetes cluster, it would be very cool! But alas, the pipeline only targeted amd64, but since it is open source I felt like I could port it to the arm64 architecture.

## Moving Parts

It turns out that there are nine different images that need to be re-built to target different architectures! Building all of the images is handled by the `hack/release.sh` script. It is unfortunate that as written, the `tekton/pipeline` build process is *also* constructed to only expect amd64 targets, and so it too had to be changed.

### `go test -race`

A key part of the `hack/release.sh` process is execution of `go test -race`, but this only targets a small set of platforms:

```shell
$ $GOPATH/src/github.com/tektoncd/pipeline
go test: -race is only supported on linux/amd64, linux/ppc64le, freebsd/amd64, netbsd/amd64, darwin/amd64 and windows/amd64
```

This is easily tackled if we can agree that running the race test isn't strictly required to start building. Running either with `--skip-tests`, or installing some "guardrails" around the tests with this diff will do just that.

```diff
diff --git a/vendor/github.com/knative/test-infra/scripts/library.sh b/vendor/github.com/knative/test-infra/scripts/library.sh
index 1b9ee07..13c45be 100755
--- a/vendor/github.com/knative/test-infra/scripts/library.sh
+++ b/vendor/github.com/knative/test-infra/scripts/library.sh
@@ -273,6 +273,24 @@ function report_go_test() {
   # go doesn't like repeating -v, so remove if passed.
   local args=" $@ "
   local go_test="go test -race -v ${args/ -v / }"
+  VALID="linux/amd64 linux/ppc64le freebsd/amd64 netbsd/amd64 darwin/amd64 windows/amd64"
+
+  myarch_i="$(uname -s)/$(uname -m)"
+  myarch="$(echo $myarch_i | tr '[A-Z]' '[a-z]')"
+
+  match=0
+  for v in $VALID
+  do
+    if [[ "${myarch}" == "${v}" ]]; then
+      match=1
+      break
+    fi
+  done
+
+  if [[ $match -eq 0 ]]; then
+    echo "Skipping ${go_test} because ${myarch} isn't supported"
+    return 0
+  fi
   # Just run regular go tests if not on Prow.
   echo "Running tests with '${go_test}'"
   local report=$(mktemp)
```

### Porting Base Images

The next hurdle was that none of the resulting images worked because the underlying base image, `gcr.io/knative-nightly/github.com/knative/build/build-base:latest` has amd64 architecture. This image had to be rebuilt. This is a straightfoward alpine base; my arm64 version is `thedoh/arm64-tektoncd-pipeline-cmd-build-base:latest`.

Once the base image is retargeted, the following diff updates `.ko.yaml` and `.ko.yaml.release` to use it. (Note: For my purposes I did not need to address the gsutil image since I'm never going to target Google services.)

```diff
diff --git a/.ko.yaml b/.ko.yaml
index 9b34cc2..1f1a3df 100644
--- a/.ko.yaml
+++ b/.ko.yaml
@@ -1,7 +1,7 @@
 baseImageOverrides:
   # TODO(christiewilson): Use our built base image
-  github.com/tektoncd/pipeline/cmd/creds-init: gcr.io/knative-nightly/github.com/knative/build/build-base:latest
-  github.com/tektoncd/pipeline/cmd/git-init: gcr.io/knative-nightly/github.com/knative/build/build-base:latest
-  github.com/tektoncd/pipeline/cmd/bash: busybox # image should have shell in $PATH
-  github.com/tektoncd/pipeline/cmd/entrypoint: busybox # image should have shell in $PATH
+  github.com/tektoncd/pipeline/cmd/creds-init: thedoh/arm64-tektoncd-pipeline-cmd-build-base:latest
+  github.com/tektoncd/pipeline/cmd/git-init: thedoh/arm64-tektoncd-pipeline-cmd-build-base:latest
+  github.com/tektoncd/pipeline/cmd/bash: arm64v8/busybox
+  github.com/tektoncd/pipeline/cmd/entrypoint: arm64v8/busybox
   github.com/tektoncd/pipeline/cmd/gsutil: google/cloud-sdk:alpine # image should have gsutil in $PATH
diff --git a/.ko.yaml.release b/.ko.yaml.release
index c8692b9..90c81cb 100644
--- a/.ko.yaml.release
+++ b/.ko.yaml.release
@@ -1,7 +1,7 @@
 baseImageOverrides:
   # TODO(christiewilson): Use our built base image
-  github.com/tektoncd/pipeline/cmd/creds-init: gcr.io/knative-release/github.com/knative/build/build-base:latest
-  github.com/tektoncd/pipeline/cmd/git-init: gcr.io/knative-release/github.com/knative/build/build-base:latest
+  github.com/tektoncd/pipeline/cmd/creds-init: ko.local/github.com/tektoncd/pipeline/build-base:latest
+  github.com/tektoncd/pipeline/cmd/git-init: ko.local/github.com/tektoncd/pipeline/build-base:latest
   github.com/tektoncd/pipeline/cmd/bash: busybox # image should have shell in $PATH
   github.com/tektoncd/pipeline/cmd/entrypoint: busybox # image should have shell in $PATH
   github.com/tektoncd/pipeline/cmd/gsutil: google/cloud-sdk:alpine # image should have gsutil in $PATH
```

Once the `.ko.yaml*` files are updated, and the `hack/release.sh` patch is applied, the `hack/release.sh --nopublish --notag-release --skip-tests` script can be run, and results in a series of images that (can be retagged and) used in a release manifest. My builds are:

* `thedoh/arm64-tektoncd-pipeline-cmd-entrypoint@sha256:59b1201290af2e0fd34299d512b6be96d623585e9be413a808bbfb83c6472e63`
* `thedoh/arm64-tektoncd-pipeline-cmd-kubeconfigwriter@sha256:dfb10be1917d7e8c6a4d2eaa0ffc483586cd35524c6e8125dc6975737f19e997`
* `thedoh/arm64-tektoncd-pipeline-cmd-creds-init@sha256:ca5b0dbfefb2dd8bbe6b91de6101ecb4c054d864896c0d5c556d78953336d619`
* `thedoh/arm64-tektoncd-pipeline-cmd-git-init@sha256:e38cb46dd8cfae142ef45c1e5bf4a6ceff8f059b2afa2e7405dd3d811311c17c`
* `thedoh/arm64-tektoncd-pipeline-cmd-nop@sha256:09b013f1e3f9f3c8fa64c8befa3a7bd71ead9f8822ac1c32b2f1ef1338bbd78f`
* `thedoh/arm64-tektoncd-pipeline-cmd-bash@sha256:b98a74da79c847a600d4d98a47abc4ea8407b1826276600b403846e2ab43a29e`
* `thedoh/arm64-tektoncd-pipeline-cmd-gsutil@sha256:b1b69e4dc0d066fff501bbc7b76abf48b9071fa0debc386605fe890f3539482c`
* `thedoh/arm64-tektoncd-pipeline-cmd-controller@sha256:c33c6f418a764ad770bd4e5f66f4680cf9e8d04c4eec05fb8780d5f21600d77c`
* `thedoh/arm64-tektoncd-pipeline-cmd-webhook@sha256:c9bd46e468c37195d3688a89ebd63cae8434bd537a08ab5248812cf746a4e8a0`

An interesting thing of note is that many of these images have manifests which show them to be amd64 images, however, the Go-built binaries `tektoncd/pipeline` uses *are* arm64 binaries, and still work.

### Installation

Finally, once the images are built, the pipeline can be installed with [this manifest](https://gist.githubusercontent.com/lisa/ca7e9e2d33559a97a50cfc7b8ab6c43b/raw/d33f7e585f76adfa801706b4f9c128a995eb6a19/release.yaml):

```shell
kubectl apply -f https://gist.githubusercontent.com/lisa/ca7e9e2d33559a97a50cfc7b8ab6c43b/raw/d33f7e585f76adfa801706b4f9c128a995eb6a19/release.yaml
```

## Building Docker Images

Installing `tektoncd/pipeline` is only a third of the puzzle for my goal of creating a [musl-cross](/docker/docker-musl-cross.html) pipeline in [my cluster](./rock64-cluster.html).

It's a known issue that running `docker build` from within Kubernetes or Docker is dangerous, but [GoogleContainerTools/kaniko](https://github.com/GoogleContainerTools/kaniko) offers a solution. However, it too only targets amd64 architecture and would need to be rebuilt to target arm64 as well.

kaniko is made up primarily of these projects:

* [GoogleCloudPlatform/docker-credential-gcr](https://github.com/GoogleCloudPlatform/docker-credential-gcr)
* [awslabs/amazon-ecr-credential-helper](https://github.com/awslabs/amazon-ecr-credential-helper)
* Code from [GoogleContainerTools/kaniko]((https://github.com/GoogleContainerTools/kaniko)) itself

In the [stock Dockerfile](https://github.com/GoogleContainerTools/kaniko/blob/c8fabdf6e43b19f6a223f1d0b06e127d0774bd7e/deploy/Dockerfile#L19-L22), kaniko fetches a docker-credential-gcr release tarball (version 1.5.0, for amd64) and extracts its contents to `/usr/local/bin/docker-credential-gcr`. There are no tarballs for arm64.

As I learned, that is a statically compiled binary (Note: That [project's Makefile](https://github.com/GoogleCloudPlatform/docker-credential-gcr/blob/7e55abeb1839689afa77070b523e0057a5c961cd/Makefile) does not contain any targets to *build* a static binary). This project will need to be compiled from source to get the static binary we need.

Next is [awslabs/amazon-ecr-credential-helper](https://github.com/awslabs/amazon-ecr-credential-helper), and there's nothing special here to do at all aside from a minor change to remove explicit reference to `linux-amd64` from the `make` command.

Finally, the `scratch` image is used as a base and binary objects are copied from the `builder` layer. (Note: A correspondingly small change was required to match up with the `amazon-ecr-credential-helper` change.)

The kaniko image is built and tagged as `thedoh/arm64-kaniko-executor:0.9.0` from a [modified Dockerfile](https://gist.github.com/lisa/c4acfd087387602f193bf2bc23ffb64d) (with the "debug" and "warmer" images ignored).

Building the kaniko image wasn't the end of the story because as @MansM [points out](https://github.com/GoogleContainerTools/kaniko/issues/530#issuecomment-466060614) in [GoogleContainerTools/kaniko#530](https://github.com/GoogleContainerTools/kaniko/issues/530), one must "...specify the arch in [the] Dockerfile." 

### Kaniko and Manifest Lists

As of [7901c761](https://github.com/GoogleContainerTools/kaniko/commit/7901c76127bec751f16afc5ed6ce24d5db3fef1c), kaniko does not support container images with manifest lists (refer to [this blog post for more background](https://medium.com/@mauridb/docker-multi-architecture-images-365a44c26be6)), which are crucial for cross-platform container images that appear to share the same name. That is, intead of `thedoh/musl-cross:1.1.22-arm64` and `thedoh/musl-cross-1.1.22-amd64`, there is instead the single image `thedoh/musl-cross:1.1.22` that self-contains the information for *both* `aarch64` *and* `amd64` platforms.

I opened a [pull request](https://github.com/GoogleContainerTools/kaniko/pull/646) to change the behaviour so that kaniko will attempt to use the manifest for the current platform, if it exists. This image is tagged as `thedoh/arm64-kaniko-executor:pr646`.

## Building [musl-cross](/docker/docker-musl-cross.html)

Once `tektoncd/pipeline` is running and the `thedoh/arm64-cloudbuild:18.04` image is available, the following Kubernetes objects will build the [musl-cross](/docker/docker-musl-cross.html) image using [musl-libc-1.1.20](https://www.musl-libc.org/).

```yaml
---
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: docker-musl-cross-img
spec:
  type: image
  params:
    - name: url
      value: thedoh/musl-cross

---
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: docker-musl-cross-git
spec:
  type: git
  params:
    - name: url
      value: https://github.com/lisa/docker-musl-cross.git
    - name: revision
      value: 1.1.20-aarch64
---
apiVersion: tekton.dev/v1alpha1
kind: Task
metadata:
  name: docker-musl-cross-pipe
spec:
  inputs:
    resources:
      - name: workspace
        type: git
    params:
      - name: pathToDockerfile
        description: Where's the Dockerfile?
        default: Dockerfile.aarch64
      - name: muslVersion
        description: musl-libc version to use
        default: 1.1.20
  outputs:
    resources:
      - name: builtImage
        type: image
  volumes:
    - name: docker-cfg
      secret:
        secretName: kaniko-secret
        items:
          - key: config.json
            path: config.json
  steps:
    - name: dockerfile-build
      image: thedoh/arm64-kaniko-executor:0.9.0
      command:
        - /kaniko/executor
      args:
        - --dockerfile=/workspace/workspace/${inputs.params.pathToDockerfile}
        - --context=dir://workspace/workspace
        - --destination=${outputs.resources.builtImage.url}:${inputs.params.muslVersion}
      volumeMounts:
        - name: docker-cfg
          mountPath: /kaniko/.docker/
---
apiVersion: tekton.dev/v1alpha1
kind: TaskRun
metadata:
  name: docker-musl-cross-run
spec:
  taskRef:
    name: docker-musl-cross-pipe
  inputs:
    resources:
      - name: workspace
        resourceRef:
          name: docker-musl-cross-git
  outputs:
    resources:
      - name: builtImage
        resourceRef:
          name: docker-musl-cross-img
```

(Note: The referenced `Secret`, `kaniko-secret`, is omitted for security reasons.)

To build version musl-libc-1.1.22 the following `TaskRun` object is created in the cluster:

```yaml
apiVersion: tekton.dev/v1alpha1
kind: TaskRun
metadata:
  labels:
    tekton.dev/task: docker-musl-cross-pipe
  name: docker-musl-cross-run-1-1-22
  namespace: tekton-pipelines
spec:
  inputs:
    resources:
    - name: workspace
      paths: null
      resourceRef:
        name: docker-musl-cross-git
      resourceSpec: null
    params:
    - name: muslVersion
      value: 1.1.22
  outputs:
    resources:
    - name: builtImage
      paths: null
      resourceRef:
        name: docker-musl-cross-img
      resourceSpec: null
  taskRef:
    kind: Task
    name: docker-musl-cross-pipe
```
