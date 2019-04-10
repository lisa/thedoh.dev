---
title: docker-static-python
parentcategory: docker
category: docker-static-python
---
# docker-static-python

As mentioned in the [docker-musl-cross](./docker-musl-cross.html) page, this `docker-static-python` container is a fork of a fork. The same upstream maintainer for the `docker-musl-libc` container has collection of [static binary containers](https://github.com/andrew-d/static-binaries), in which is the Python container. I created a [fork](https://github.com/lisa/static-binaries) of the upstream branch, inside which [I upgraded the Python version](https://github.com/lisa/static-binaries/tree/update-python-version) and demonstrated the ability to statically include other libraries into the Python binary.

## Python With Static Libraries

During the course of my investigation with the [upstream container](https://github.com/andrew-d/static-binaries) I wanted to make a demo of various ways to use Python in this way. To that end I wanted to illustrate the different process ID (`pid`) of the process inside the container that was doing the interesting work. That is, if there's a `fork(2)` taking place the `pid` of the "work" will not be `1`.

In the course of that I ran across the [psutil](https://github.com/giampaolo/psutil) Python library which would allow me to access the process's ID. As it happens, `psutil` executes C code to achieve its goals and thus it wants to be dynamically linked (as do all Python modules by default). Dynamic linking will not work with a statically compiled container and so I set out to figure out how to get `psutil` to statically compile into the Python binary.

The commit for it is [in a branch](https://github.com/lisa/static-binaries/commit/c1536cc8a80461c3f41538170a39da0ed5255535). It wasn't straightforward.

First, and foremost, was an [upstream Python bug](https://bugs.python.org/issue7938) ([cpython PR](https://github.com/python/cpython/pull/4338)) which I was able to include with the container build process.

Next were two `psutil` issues that aren't really upstream defects, but are a side effect of the weird packaging contorting one must do for this static compilation business. Because the C modules `psutil` expects fo find aren't in the same directory as the Python module files the upstream [__init__.py](https://github.com/giampaolo/psutil/blob/91b0d9c05d5781d3cf6594f2a3660ee897be0345/psutil/__init__.py#L99) and [\_pslinux.py](https://github.com/giampaolo/psutil/blob/91b0d9c05d5781d3cf6594f2a3660ee897be0345/psutil/_pslinux.py#L26-L27) files needed to be patched so that `psutil` will look _anywhere_ for its libraries. These were patched during the build process. I also had to move `psutil`'s files around so that the Python library files could be copied into the resulting zipped libraries file.

And finally, in what in hindsight was a kind of "oh yeah, of course" moment, the container has pieces to it which make certain syscalls, such as Flask to find out which user it is running under. To that end I had to populate `/etc/passwd` with an entry, which I chose as the root user.

In the end, `psutil` was compiled into the Python binary inside the container and that proved the possibility of statically compiling "arbitrary" libraries. Without a doubt there exist a set of libraries for which this approach will not work.

## Static Python Container Examples

Alluded to earlier are usage examples:

* [Python subprocess](https://github.com/lisa/docker-sample-static-python/tree/master/subprocess)
* [execv](https://github.com/lisa/docker-sample-static-python/tree/master/execv)
* [factory pattern with Flask](https://github.com/lisa/docker-sample-static-python/tree/master/factory)
