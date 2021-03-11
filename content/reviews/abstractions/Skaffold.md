---
title: "Skaffold"
date: 2020-12-04T08:48:36-08:00
draft: true

github: "https://github.com/GoogleContainerTools/skaffold"
homepage: "https://skaffold.dev"
icon: "google.png"
sponsors: []
tagline_1: "Easy and Repeatable Kubernetes Development"
tagline_2: ""
---


Skaffold allows you to quickly iterate while developing Kubernetes applications by automating the build, push, and deploy steps of a the cycle.

It also comes with a nifty development mode to rebuild and deploy your application when a file changes. This can dramatically speed up your software development.

# Experience

## Design

Skaffold is completely client side and relies on the same config as `kubectl`. By default, it builds the container locally using Docker and pushes the container to your Dockerhub account. At the time of this writing, there are options for Buildpacks and Kaniko to allow for remote building of images.




# Review

## Prior knowledge needed

- Container Basics
- Kubernetes Basics

## Sample

This might be the shortest sample of all of these reviews due to how amazingly easy to use skaffold is!

Since the maintainers of Skaffold have provided a [massive amount of samples to use](https://github.com/GoogleContainerTools/skaffold/tree/master/examples), I'll go with something they don't have but I've used in a few other reviews: WordPress development.

To do this, I need to build a few files for Skaffold to use:

- Dockerfile
- yaml files for deployment, service, and ingress


### Build dockerfile




## Pros

- Easy to use
- Solves a real problem of how to quickly build and move images without needing to do it all manually.
- Takes care of much of the developer frustration in their inner loop with the `dev` command

## Cons

- Exposes Kubernetes primitives to the developer
- Defaults to requiring full Docker installation

# Conclusion

Skaffold does a great job of solving the problem of how to get code running in a Kubernetes cluster. My main complaint with it is that there is too much infrastructure knowledge needed for the developer to be productive. That said, this could likely be fixed for some teams by having a collection of templates maintained by a team more familiar with Kubernetes. 

All in all, this is a fantastic tool if you are already bought into Kubernetes and just looking to make development faster!
