---
title: "Cloud Native Developer Tools"
date: 2019-03-26T08:47:11+01:00
draft: false
---



# Purpose of this Series

In the Cloud Native world, the landscape of what a software engineer needs to know has exploded in the last few years and has become increasingly complex. We have seen an explosion in tools available for our operator friends but developers have been left behind.

In this blog series, I will be reviewing tools geared at helping developers get back to what we do best: write interesting code!

Each week (or every other when needed), I will pick a tool from the map below to write a review and record a demo of something that differentiates it from other options. As I go, I'll edit this page to show the most recent list of blog entries.


Note that this is very much a continual work in progress and as I get feedback and learn, I'll try to update all of the entries with new formats. 

# Tools Map

{{<tools-map >}}

### Why not just use the published CNCF Landscape?

I went back and forth on this if I should or not. I think there's a lot of value in the CNCF landscape but it's too overly complex for programmers when not already familiar with Kubernetes and it's ecosystem. 

The goal here is to try to pull out the specific pieces and options that a developer (or team of developers) would need to know in a way that is accessible without the larger infrastructure background.


## I just want to develop! Where should I start?

Even with this smaller landscape, there are still a lot of choices. If you are just getting started, here are a few stacks to try:

### Gitlab

While it's not in the map above, Gitlab has an offering called [Auto DevOps](https://about.gitlab.com/stages-devops-lifecycle/auto-devops/) if you don't want to run your own infrastructure. It just works.


### Beginner Friendly

For a beginner friendly setup, I would recommend using:

- [K3S](https://k3s.io) 

Makes it easy to install a Kubernetes cluster. If you are on Mac of Windows, [Minikube](https://minikube.sigs.k8s.io/docs/) can be useful as well!

- [Jenkins X](https://jenkins-x.io)

Has made it very easy to get started from scratch without needing to learn the underlying platform. Try the quick start and then adapt to your own project! 

- [Code Server](https://github.com/cdr/code-server)

Let's you edit your code in a browser from anywhere. It can be installed on a server somewhere, as a container, or in Kubernetes directly (with some extra work to configure).

- [OpenTelemetry](https://opentelemetry.io)

While this isn't a single tool, I would highly recommend learning how to instrument your code in a way that is friendly to micro-services. Your life as a developer will get much nicer when you don't have to dig around in each container trying to find where a bug happened.

### My Personal Setup

For my own use, I tend to like building my own "platform" to work with so my flow is a little more complicated to set up:

- [K3S](https://k3s.io) 

I love the simplicity of this project.

- [Tekton CI/CD](https://tekton.dev)

This let's me write scripts that might be outside of projects in a way that works the way I think about code.

- [Cloud Native Buildpacks](https://buildpacks.io)

I'm still adopting my pipelines to this but I really like it do far. I know the concepts from Heroku and Cloud Foundry. Using this instead of Dockerfiles can let me streamline projects without needing to write individual builds.

- [Code Server](https://github.com/cdr/code-server)

I customized Code Server to run on top of the OpenSUSE base container. This let's me use all the tools that I'm already familiar with without any issues! 


## Contributing

If you know of a tool that should be here, please let me know in the [SUSE Community](https://community.suse.com) (Once it is live!) or open up a issue in Github.

Also, if there's anything that's not clear in any of these reviews or I'm making any mistaken assumptions, please let me know! Either in a Github ticket or (preferably) by posting in the [SUSE Community](https://community.suse.com)


