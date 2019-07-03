---
title: docker-musl-libc
parentcategory: docker
category: docker-musl-libc
description: |
  musl-libc static compiler in a container
---
# docker-musl-libc

[lisa/docker-musl-libc](https://github.com/lisa/docker-musl-cross) is created as a fork of [andrew-d](https://github.com/andrew-d/docker-musl-cross)'s work. I created the fork to update the version of [musl-libc](https://www.musl-libc.org/), as the upstream maintainer appeared to be on hiatus.

# Usage

## Python 2.7

The container is used to build the [Static Pyton container](./docker-static-python.html), which itself is a fork of a fork. Read up on that page for more details.

## Other Uses

I've attempted to get Ruby and Python 3.x to statically compile, but those have been put on hold.
