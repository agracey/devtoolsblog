---
title: "Buildah"
date: 2021-01-21
draft: false

github: "https://github.com/containers/buildah"
homepage: "https://buildah.io"
icon: buildah.png
sponsors: []
tagline_1: "A tool that facilitates building OCI images"
tagline_2: ""

author: "Andrew Gracey"
author_bio: "Developer Advocate at SUSE, focusing on making Cloud Native development less painful"

version: v1.17.1
---


Buildah is a tool to build containers without needing the full Docker stack installed, running, and accessible. Due to this it can be run in a much more secure way and with more flexibility. 

It also allows more fine tuning of what goes into container images as well as running without needing root access to the build server.


# Experience
Like a few of the other tools here, I've used Buildah for a couple years. As usual, I will try to be as unbiased as possible but please let me know if you believe I've missed (or ignored) anything by accident!


## Design
What makes Buildah different from other tools is that it allows the user to control the build flow from outside of the tool (as opposed to Docker where you just let it do it's thing unattended). 

The typical flow when creating a container (in some order):

- Create container from either "scratch" or a base container
- Mount the container and add files 
- Run scripts in the container's context
- Commit container
- Edit manifest

As you'll see in the example, Buildah has commands for each of these tasks.

### Ecosystem

Buildah is part of the set of Open Source container tools that also contains CRI-O, Podman, and Skopeo. These all share common configuration and base libraries together to give a fully featured user experience. 

There is some overlap between each tool in this set and it can be a little confusing as (for example) Podman is a complete drop-in replacement for docker on the command line so it can also build and manage container images.


# Review

## Prior knowledge needed

- Container Basics
- Shell Scripting
- Potentially some in depth Linux knowledge if you need to push the boundaries 


## Installation

Buildah is purely a command line tool for Linux and can be installed from both .rpm or .deb packages.

### What privileges are needed

- Root or Sudo on a Linux host to install and setup user config 

### Steps

As I'm running on an OpenSUSE Leap 15.2 system for my desktop, the installation is done simply with the Zypper tool:

```bash 
sudo zypper install buildah
```

This will install the tool itself. 

If you want to run rootless (allows building containers without needing to run `sudo` before each command), you need to edit two files:

```bash
sudo echo `whoami`:10000:100000 >> /etc/subuid
sudo echo `whoami`:10000:100000 >> /etc/subgid
```

This change also affects the full [CRI-O](https://cri-o.io), [Podman](podman.io), and [Skopeo](https://github.com/containers/skopeo) tool-chain as well to allow for a fully rootless and more secure way of building and running containers!


Support for more operating systems can be found at https://github.com/containers/buildah/blob/master/install.md

### Sample

For this sample, we are going to create a simple Nginx container based on OpenSUSE.



First things, to run rootless, we will likely need to enter a "shared namespace" so that our permissions can bridge between different container contexts:

```bash
buildah unshare
```

This will put us into a new shell.

To start a new container build we can run:


(TODO: complete)

#### Signing the Container (TODO: learn and write)

## Pros

- Daemon-less builds (no service needs to be running)
- Root-less builds (no need for sudo access)
- Fully scriptable
- Multi-Architecture friendly

## Cons

- Permissions can be a bit confusing when in nested namespaces
- More complicated than similar tools
- Might be difficult to tie into CI/CD systems

## Ideal Projects

There are a few places where I see buildah having an advantage at the moment:

- Projects that already have a build pipeline creating a binary and just need to package it into a container

It makes it very easy to build a scratch container, mount it, and add the binary without needing anything else.

- Projects that need the flexibility in their build to parallelize different build stages

Since you get a lot more flow control between steps, you can move intermediate results around between different containers and the host system.

- Projects that need multiple architecture support easily provided

You can more easily edit container manifests with buildah before committing giving access to more advanced use cases. 


# Conclusion


When I first started using Buildah (mid 2019?), it was by far the best tool for the job as I wanted more flexibility than a Dockerfile could give. I think that at the time of this writing, I will probably reach for it less often as the more advanced use cases are filled by other newer tools. 

That said, if you want something extremely flexible to build images in or are running up against limitations, it's a very good choice!


(TODO: complete)
