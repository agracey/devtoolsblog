---
title: "Tekton"
date: 2020-12-28
draft: false

github: "https://github.com/tektoncd"
homepage: "https://tekton.dev"
icon: "tekton.png"
sponsors: []
tagline_1: "Tekton is a powerful and flexible open-source framework for creating CI/CD systems, allowing developers to build, test, and deploy across cloud providers and on-premise systems"
tagline_2: ""


author: "Andrew Gracey"
author_bio: "Developer Advocate at SUSE, focusing on making Cloud Native development less painful"

version: v0.19.0
---


# Tekton 

For today's review, I'm going to look into [Tekton](https://tekton.dev). It is a fully [Kubernetes](https://kubernetes.io) Native CI/CD runner. 


One of it's unique selling points is that it separates the process (Pipeline), the scripts being run (Tasks), the code, and the trigger to actually start the process. This decoupling allows for less duplication across projects as well as a similar decoupling in who is responsible for each part of the process.

This allows for a powerful way to break apart both the build process and the human responsibilities into more flexible pieces.


# Experience
 
Note: I've used Tekton a few times before and it's my preferred script runner as I'm the most comfortable with it and I have a personal library of tasks. 

I've been using Kubernetes for a while now so I personally liked the tight integration with the platform and working with CRDs (and YAML) was not a new concept. Depending on your background (and how you think about CI/CD), you might count that as a Pro or Con. Also, prior to this review, I had not used the CLI. I typically disagree with each tool offering it's own CLI.

My experience with Tekton has been very positive with only a few expectations. One of my main complaints is that there was a architectural change at some point in the not to distant past that broke a lot of 3rd party documentation. This is a problem shared by a lot of earlier stage projects and I hope that as it moves forward, the 



## How it Works

To achieve the flexibility it needs, Tekton has a bit of a "nesting doll" of ideas that are used to put together useful pipelines.

Tasks are the most basic level of control. A Task object allows for you to write which programs should be run, in which container images, and in what order. It also allows for a Task author to specify inputs and outputs (and defaults) that are needed for the Task to run. 

The steps in a task share a pod (meaning that they share a filesystem and resources)


TaskRuns manage the life cycle of a Task to create a Kubernetes Pod with all the required configuration then collect the output of the Pod.



One step higher, Pipelines add the ability to run multiple Tasks in parallel as well as share a workspace (either in the form of a PersistentVolume or Minio/S3 bucket). This allows for defining a shared set of Task definitions then composing them into a fully featured process.

Like TaskRuns, PipelineRuns manage the life cycle of Pipelines. 


Along with these base components, there is also the Trigger component which maps external HTTP(s) addresses into PipelineRuns for use as web-hooks (e.g. triggering a PipelineRun when Github reports a PR merge)


# Usage

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

The installation is relatively straightforward if you have access to a Kubernetes cluster and includes applying a few chunks of pre-rendered YAML found at: https://tekton.dev/docs/getting-started/


There are also a Tekton Triggers and a Dashboard that can be included to add significant flexibility.



### What privileges are needed to install / use

- Cluster Admin to create CRDs on installation
- Individual users (and scripts) can be given access to specific namespaces and scripts.
- Service Accounts to allow for safe deployment of built application

### Steps

For this installation, I'm using a single node (k3s)[k3s.io] cluster on an Intel NUC.  

#### Base

The base installation is just applying the provided yaml file.

```bash
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

This will install the CRDs, the roles and role bindings, and the deployments to operate on the CRDs. 



To install the command line tools, I can use the provided rpm to install with zypper.

```bash
sudo zypper in https://github.com/tektoncd/cli/releases/download/v0.15.0/tektoncd-cli-0.15.0_Linux-64bit.rpm
```

#### Dashboard

The dashboard is similarly easy and can be installed with this provided set of yaml:

```bash
kubectl apply -f https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml
```

To actually access the dashboard, I needed to do a portforward or create an Ingress object:

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: tekton-dashboard
  namespace: tekton-pipelines
spec:
  rules:
  - host: tekton.192.168.1.10.xip.io
    http:
      paths:
      - backend:
          serviceName: tekton-dashboard
          servicePort: 9097
        pathType: ImplementationSpecific
```

Now browsing to `tekton.192.168.1.10.xip.io` pulled up the dashboard!

#### Triggers

Lastly, we can setup the triggers so we can use webhooks or other external action to start pipeline runs.

As with the other components, we can install with its own yaml file.

```bash
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```


#### Command Line Tools

Tekton comes with a useful commandline tool to work with tasks and pipelines.

Since I'm running on OpenSUSE (an RPM based distro), I can install the rpm directly using:

```bash
sudo zypper in https://github.com/tektoncd/cli/releases/download/v0.15.0/tektoncd-cli-0.15.0_Linux-64bit.rpm
```

Oddly enough, the package is called just `cli` which I think could create confusion later.


### Sample

To show how Tekton uses Yaml to define tasks and pipelines, I built a pretty simple and self-contained example. In it, we wait for a set amount of time then print a string. Both the string and delay are configurable and are split between two tasks.

To start, create a Task called `sleep` containing:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: sleep
spec:
  params:
    - name: time-to-sleep
      type: string
      default: "30"
      description: How long to wait
  steps:
    - name: sleep
      image: registry.opensuse.org/opensuse/leap:15.2
      command:
        - sleep
      args: 
        - $(params.time-to-sleep)
    - name: print-done
      image: registry.opensuse.org/opensuse/leap:15.2
      command:
        - echo
      args: 
        - "Done Sleeping!"
```

It will sleep for the time requested (through the params object) then prints "Done Sleeping!" to the logs.

Next create a Task called `print`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: print-text
spec:
  params:
    - name: text-to-echo
      type: string
      default: "This is very contrived"
      description: Text To Echo Out
  steps:
    - name: hello
      image: registry.opensuse.org/opensuse/leap:15.2
      command:
        - echo
      args: 
        - $(params.text-to-echo)
```

Similarly, this prints the requested Text!

These can be run independently with `tkn task start sleep` or `tkn task start print` but that misses out on much of the flexibility of Pipelines.

To combine these Tasks create a Pipeline with both of them specified:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: mock-pipeline
spec:
  params:
    - name: time-to-sleep
      type: string
      default: "30"
      description: How long to wait
  tasks:
    - name: pull-code
      taskRef:
        name: print-text
      params:
        - name: text-to-echo
          value: "Maybe pulling some code from git?"
    - name: build
      runAfter: 
      - pull-code
      taskRef:
        name: sleep
      params:
        - name: time-to-sleep
          value: $(params.time-to-sleep)
    - name: print2
      runAfter: 
      - build
      taskRef:
        name: print-text
      params:
        - name: text-to-echo
          value: "This could be a deploy?"
```


This Pipeline runs the `print-text` task to print "Maybe pulling some code from git?", then sleeps for a request amount of time, then runs `print-text` again to print "This could be a deploy?" 

To run this pipeline, use:

```bash
tkn pipeline start mock-pipeline
```

It will prompt for how long to wait then print a command to use for viewing logs that looks similar to:

```bash
tkn pipelinerun logs mock-pipeline-run-zv6vs -f -n default
```

If you run this you will see all (or part if it's still sleeping) of this output:

```bash
[pull-code : hello] Maybe pulling some code from git?


[build : print-done] Done Sleeping!

[print2 : hello] This could be a deploy
```


While these tasks are overly simple, there are a lot of pre-built tasks in [the provided catalog](https://github.com/tektoncd/catalog/tree/master/task) that can be used to easily create powerful pipelines. And since they are all yaml, it's simple to modify them as needed!

In future blogs, I'll go through using either Kaniko or Cloud Native Buildpacks to build images. Tekton has good support for both of these methods.

## Pros

- Highly composable
- Very powerful with good abstractions
- Solid Security due to ability to use Pipeline specific Service Accounts
- Growing set of published Tasks for anyone to use available on their [Github catalog repo](https://github.com/tektoncd/catalog).

## Cons

- As it is based on Kubernetes and CRDs, there is no way to use Tekton outside of Kubernetes.
- Needs cluster admin access to install and operator
- Not beginner friendly (Steep learning curve)

## Ideal Projects

Tekton is a great solution for projects (and teams) where it makes sense to keep your pipelines separate from the code being built. This can be a useful pattern if you have several components that have the same or similar build processes because you can evolve governance in a more ,centralized way.


My prediction is that it will be used by a lot of companies' backbone for release teams looking to build custom PaaS-like solutions and give a good separation of concerns between departments. 


While Tekton is my personal choice because it gives a set of abstractions that I like to think with, it's potentially a poor choice for teams with relatively few components or who don't want (or need) to jump on the Kubernetes bandwagon.

# Conclusion


Tekton is a fantastic project with a lot of cool ideas on minimalism. Teams who are already bought in to Kubernetes would likely enjoy using Tekton and find it easy to manage.

I'm very excited to see where this project goes in the future!