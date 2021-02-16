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

## Sample

For this sample, we are going to create a simple Nginx container based on OpenSUSE.


#### Base Layer

Create the base layer and hold on to the name for later steps.

For ease of instruction we will start with a OpenSUSE specific base layer (which I choose to trust). For containers without dependencies (where the application is a compiled binary), you can use `buildah from scratch` to start with an empty layer.

```bash
ctr=$(buildah from "registry.opensuse.org/opensuse/leap:15.2")
```

NOTE: For most scripts it’s easier to just capture it in the first step and just use it as a variable. If you are doing this manually,the value can be found as the Container ID in the output of:

```bash
buildah containers
```

#### Installing packages

Now that we have the base layers of the container, let’s add to it. There are two ways to go about this: 
- Mount the container filesystem and use zypper (or any package manager) to install into it
- Run zypper (or any package manager) from inside the container
- Copy only relevant files into the right directory

Each of these options have their time and place. As we are running rootless, we cannot run our package manager from the host so the first option is out. Since we want to use our package manager to install nginx and all of it's needed dependencies, we will run zypper from inside the container.

This is done with:

```bash
buildah run $ctr zypper in nginx
```

This will need to update the registry metadata then will install nginx into the container.

#### Committing the layer

It's good practice to split your images into logical layers. This does two things: You don't have to continually rebuild your image from scratch, and different nodes can share any common layers between them instead of having to re-download full images each time.

We can commit the layer and then continue building onto it using:

```bash
image=$(buildah commit --rm $ctr leap_with_nginx)
ctr=$(buildah from $image)
echo $ctr
```

Note: The `--rm` flag instructs buildah to remove the previous working container after committing. This way we don't waste storage.


#### Writing Nginx Config

Next we will write the nginx config needed to tell it how to host our files.

To do this we will mount the container filesystem to a place we can access from the host. There is a little weirdness in this step sicne we are running as a non-root user and we will need to run in a shared user namespace. To do this, run:

```bash
podman unshare 
```

This will start a shell in a separate linux namespace where we have more permissions but are still safely segmented out from the rest of the system. Please note that the variables we were using don't come with us (which is the reason for echoing it out in the previous step).

To mount the container we are working on we can use:

```bash
ctr="leap_with_nginx-working-container" # or the output of `echo $ctr` above
ctr_wd=$(buildah mount $ctr)
```

The stored output tells you where to find the root of the container's filesystem.

Using your favorite editor, create a new file at $ctr_wd/app/nginx.conf and add the following content. This will instruct nginx to listen on port 8080, run as an executable, and host files from /app/srv. Note that you will need to create the containing folder with `mkdir -p $ctr_wd/app`.

```nginx.conf
worker_processes 1;
error_log stderr;
daemon off;
pid nginx.pid;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  sendfile on;
  keepalive_timeout 65;

  server {
    listen 8080;
  
    location / {
      root /app/srv/;
      index index.html index.htm;
    }
  }
}
```

#### Adding Manifest

We need to add some config into the container manifest so it knows what to run when started. This is done with:

```bash
buildah config --cmd '' $ctr
buildah config --entrypoint '["/usr/sbin/nginx","-c","/app/nginx.conf","-p","/app/"]' $ctr
```

This will set up our container to start nginx with our newly created configuration when the container starts and to not attempt to run the default bash command.

#### Committing Layer

With those changes, we should commit again and then remount it with the following sequence of commands:

```bash
image=$(buildah commit --rm $ctr leap_with_nginx_configured)
ctr=$(buildah from $image)
ctr_wd=$(buildah mount $ctr)
```

#### Adding content

Now, with the new layer built and mounted, let’s actually add content to host into it:

```bash
mkdir $ctr_wd/app/srv
echo "Hello, World! I'm stuck in a container!" > $ctr_wd/app/srv/index.html
```

While this is a trivial example so I just echo in some content. From this shared namespace, I can copy over files from the host as well.

#### Committing Final Layer

Lastly, let’s commit that container for us to run:

```bash
buildah commit --rm $ctr my_hello_world
exit
```


#### Running Container Locally

Now that the container is created, we can run it locally using `podman` with:

```bash
podman run -p 8080:8080 my_hello_world
```

This will run with the terminal attached so you can see any output from the command. When you browse to `http://127.0.0.1:8080/` you should see the hello world in the browse and will likely see an error about a missing favicon in the command line. We didn't add one so that's expected.


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
- Documentation is a bit hard to follow if you aren't very familiar with how containers are built

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
