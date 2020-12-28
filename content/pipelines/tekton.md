---
title: "Tekton"
date: 2020-12-07T08:06:21-08:00
draft: false

github: "https://github.com/tektoncd"
homepage: "https://tekton.dev"
sponsors: []
tagline_1: "Tekton is a powerful and flexible open-source framework for creating CI/CD systems, allowing developers to build, test, and deploy across cloud providers and on-premise systems"
tagline_2: ""


version: v0.19.0
---


Tekton is a Kubernetes Native CI/CD runner. It uses Custom Resource Definitions (CRDs) to store it's configuration and control script running. 

It allows for creating pipelines of tasks that are decoupled from the task definition itself. This allows for a powerful way to break apart the build process into composable bits. 

# Experience

Note: I've actually used Tekton a few times before and it's my preferred script runner as I'm the most comfortable with it and I have a personal library of tasks. 

I've been using Kubernetes for a while now so I personally liked the tight integration with the platform and working with CRDs (and YAML) was not a new concept. Depending on your background (and how you think about CI/CD), you might count that as a Pro or Con. 



# Review

## Why should I care?

CI/CD systems are increasingly central to the software development process. A good release process should be automated in a safe way to allow for faster development cycles. 


## Prior knowledge needed

- Kubernetes Basics
- Container Basics
- YAML
- Custom Resource Definitions
- Operator Pattern (Kinda)
- CI/CD Basics
- Kubernetes Service Accounts & RBAC
- Kubernetes Volumes (or Minio/S3)

The core of the knowledge needed is Kubernetes basics. While I tend to believe that developers shouldn't need to know Kubernetes, that's not really possible in the current ecosystem. 

Custom Resource Definitions give a way to store data in the Kubernetes API in a way that other applications can work with it. This opens up the possibility of writing code that "operates" on the custom data to create other K8s objects (known as the Operator Pattern or Operators). For example, Tekton turns TaskRuns into more complicated Pods and maps the results back.




## Installation

The installation is relatively straightforward and included applying a chunk of pre-rendered YAML found at: https://tekton.dev/docs/getting-started/

You do need a user with the cluster-admin role to install the CRDs that allow the operator to work.

There are also a Tekton Triggers and a Dashboard that can be included to add significant flexibility.



### What priveleges are needed to install / use

- Cluster Admin to create CRDs on installation
- Individual users (and scripts) can be given access to specific namespaces and scripts.
- Service Accounts to allow for safe deployment of built application

### Steps

#### Base

#### Dashboard

#### Triggers


#### Sample App


## Pros

- Highly composable
- Very powerful with good abstractions
- Good Security due to ability to run stage with K8s Service Accounts least priviledges needed


## Cons

- As it is based on Kubernetes and CRDs, there is no way to use Tekton outside of Kubernetes.
- Needs cluster admin access to install and operator
- Not beginner friendly (Steep learning curve)


# Conclusion


While Tekton is my personal choice because it gives a set of abstractions that I like to thing with, it's potentially a poor choice for a newer developer or someone just looking to play around  with CI/CD ideas. 

