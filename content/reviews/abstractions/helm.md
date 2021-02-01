---
title: "Helm"
date: 2020-12-04T08:48:47-08:00
draft: true

github: "https://github.com/helm/helm"
homepage: "https://helm.sh/"
icon: "helm.png"
sponsors: ["CNCF"]
tagline_1: "The Kubernetes Package Manager"
tagline_2: ""
---

Helm is a tool that allows a developer to bundle components, dependencies, and configuration into "Charts" to be installed together. A developer can expose a selection of options to make sure configuration matches across all components. 

It also allows for upgrade, roll-back, and uninstall to be done in a clean and easy way. 



# Experience

Helm is likely one of the first tools that people get introduced to after `kubectl` when they start using Kubernetes. As such, I have used it for several years now. 


## Design

Helm 3 charts are templated yaml files that produce various Kubernetes objects. When a chart is deployed, it will populate the template based on user input, add helm-specific version info to the objects, then create or update the generated objects. 

It also keeps a copy of each version in a Custom Resource which allows for you to pull the currently installed config, edit it, and then make an update. From experience, this really helps when you have multiple people who might have made configuration changes.

Each Chart installation is tied to a namespace and is limited to the Roles bound to the current user.


(TODO: complete)


# Review

## Prior knowledge needed

- Container Basics
- Shell Scripting


## Installation

Buildah is purely a command line tool for Linux and can be installed from both .rpm or .deb packages

### What privileges are needed to install / use

While Helm 2 used a component called Tiller to manage installs, Helm 3 does it's work client side and uses the Kubernetes RBAC. Due to this, different permissions will be required for different charts. 

For demo purposes, I'll be using my Cluster Admin to do the installs. 

### Steps

On openSUSE, we can use zypper to install the Helm command:

```bash
sudo zypper in helm
```

The tool itself is a golang binary so it's possible to [install by downloading](https://github.com/helm/helm/releases). 


### Sample

As this is a Developer tools blog, let's build a sample chart that runs a wordpress instance, mysql, and sets up the routing. 

We start by using 

```bash
helm create sample-wp
```

This will create a new folder with sample yaml at `./sample-wp`



(TODO: complete)

## Pros

- Industry standard
- Good security model 
- 

## Cons

- Charts can become very complex
- Installation, Upgrades and Rollbacks are only single step (as opposed to the Operator Model which allows for a more scripted approach)

(TODO: complete)

## Ideal Projects

Any project that has a lot of potential misconfigurations would likely benefit from helm's ability to give sane but editable defaults.

It's likely not worth creating a helm chart just for a Wordpress site, but it's very useful for anyone producing reusable components (platforms, databases, authentication, etc) who wants to simplify the process of installing their software.


# Conclusion

Helm 

(TODO: complete)