---
title: "Tekton"
date: 2020-12-07T08:06:21-08:00
draft: false

github: "https://github.com/tektoncd"
homepage: "https://tekton.dev"
sponsors: []
tagline_1: "Tekton is a powerful and flexible open-source framework for creating CI/CD systems, allowing developers to build, test, and deploy across cloud providers and on-premise systems"
tagline_2: ""

type: post
kind: post

version: v0.19.0
---

# Summary

Tekton is a Kubernetes Native CI/CD runner. It uses Custom Resource Definitions (CRDs) to store it's configuration and control script running. 

It allows for creating pipelines of tasks that are decoupled from the task definition itself. This allows for a powerful way to break apart the build process into composable bits. 

# Experience

Note: I've actually used Tekton a few times before and it's my preferred script runner as I'm the most comfortable with it and I have a personal library of tasks. 



# Review

## Why should I care



## Prior knowledge needed

- Kubernetes Basics
- Container Basics
- YAML
- Custom Resource Definitions
- Operator Pattern (Kinda)
- CI/CD Basics
- Kubernetes Service Accounts & RBAC
- Kubernetes Volumes

### Context

## Installation

### What privs are needed to install / use

- Cluster Admin to create CRDs
- 

### Steps



## Pros

- Highly composable
- Very powerful with good abstractions
- 



## Cons

- As it is based on Kubernetes and CRDs, there is no way to use Tekton outside of Kubernetes.
- Needs cluster admin access to install and operator
- Not beginner friendly (Steep learning curve)


# Conclusion


While Tekton is my personal choice because it gives a set of abstractions that I like to thing with, it's potentially a poor choice for a newer developer or someone just looking to play around  with CI/CD ideas. 

