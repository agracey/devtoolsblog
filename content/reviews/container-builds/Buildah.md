---
title: "Buildah"
date: 2021-01-21
draft: false

github: "https://github.com/containers/buildah"
homepage: "https://buildah.io"
icon: containers.png
sponsors: []
tagline_1: "A tool that facilitates building OCI images"
tagline_2: ""
---


Buildah is a tool to build containers without needing docker. It can be 

# Experience
Like a few of the other tools here, I've used Buildah for a few years and use it as my main tool. As usual, I will try to be as unbiased as possible but please let me know if you believe I've missed (or ignored) anything by accident!

## Design
(TODO: complete)


# Review

## Why should I care?

While Docker was the first to market to make working with containers easy, it made some design choices that might not work for some usecases.

## Prior knowledge needed

- Container Basics
- Shell Scripting


## Installation

(TODO: complete)

### What privileges are needed to install / use

- Root on a Linux host

### Steps

As I'm running on an OpenSUSE Leap 15.2 system for my desktop, the installation is done simply with the zypper tool:

```bash 
sudo zypper install buildah
```

This will install the tool itself. 

If you want to run rootless (allows building containers without needing to run `sudo` before each command), you need to edit two files:

```bash
sudo echo `whoami`:10000:100000 >> /etc/subuid
sudo echo `whoami`:10000:100000 >> /etc/subgid
```

This change also affects the full [CRI-O](https://cri-o.io), [Podman](podman.io), and [Skopeo](https://github.com/containers/skopeo) toolchain as well to allow for a fully rootless and more secure way of building and running containers!



Support for more Operating systems can be found at https://github.com/containers/buildah/blob/master/install.md

### Sample

(TODO: complete)

## Pros

- (TODO: complete)


## Cons

- (TODO: complete)

## Ideal Projects
(TODO: complete)

# Conclusion


(TODO: complete)