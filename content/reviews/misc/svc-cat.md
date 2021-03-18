---
title: "Service Catalog"
date: 2021-03-15
draft: false

github: "https://github.com/kubernetes-sigs/service-catalog"
homepage: "https://svc-cat.io"
icon: "cncf.png"
sponsors: ["CNCF"]
tagline_1: "Consume services in Kubernetes using the Open Service Broker API"
tagline_2: ""

author: "Andrew Gracey"
author_bio: "Developer Advocate at SUSE, focusing on making Cloud Native development less painful"
---

Service Catalog is a project in the CNCF ecosystem that allows administrators to create a marketplace of services to be installed then allows users of the platform to easily install and "bind" those services to their applications.

On the back side, it's using the Open Service Broker API (OSBA) to allow for provisioning any services that have a broker created (or you can build your own if you want!). This means that you can pick from [several off the shelf solutions](https://www.openservicebrokerapi.org/compliant-service-brokers) based on the OSBA specification.

While most uses are historically databases, you could use a service broker to set up and manage any type of external dependency. 


# Experience

I've used a few versions of the OpenService Broker before and also managed a publicly facing PaaS that used Minibroker. This is my first time using the Service Catalog Operator on Kubernetes though.

## Design

Todo: list CRDs and their interactions

# Review

## Prior knowledge needed

- Kubernetes basics
- Secret management

## Installation

### What privileges are needed to install / use

Since it's built on Custom Resource Definitions (CRDs), we need to be cluster admin to install the framework itself. Once the operator and broker are installed, you can use the framework as a normal user with the right role bindings.

### Installation Steps

The installation is a few steps but reasonably straightforward. I'll be using [Minibroker](https://github.com/suse/minibroker) with a few basic customizations as my broker since it doesn't require any extra set up or accounts.

#### Service Catalog framework & operator

The first piece to install is the operator itself. We can do this with: 

```bash
helm repo add svc-cat https://kubernetes-sigs.github.io/service-catalog
helm install catalog svc-cat/catalog --namespace catalog --create-namespace
```

#### Minibroker

Next we need a broker to provide services to the marketplace. Minibroker is self contained, so let's install it.

First, we can optionally set up some overrides that ease our usage down the road using these values in `minibroker-values.yaml`: 

```yaml
provisioning: 
  mariadb:
    overrideParams:
      db:
        user: "dbuser"
        name: "default"

  postgresql:
    overrideParams:
      postgresqlDatabase: defaultdb

  mongodb:
    overrideParams:
      mongodbDatabase: defaultdb
      mongodbUsername: mongodbuser
```

This will make sure that the services that get installed by the broker have existing databases/schemas created!

Next we can install minibroker with these values

```bash
helm repo add minibroker https://minibroker.blob.core.windows.net/charts
helm install minibroker --namespace minibroker minibroker/minibroker --create-namespace -f minibroker-values.yaml
```

This will install the broker and set up the registration between the service catalog operator and the broker itself.

#### svcat

Lastly, we probably want to install the command line tool to make managing services easier. We could work with custom resources directly, but the command line option makes it much easier!

I'll use the [documented](https://svc-cat.io/docs/install/#linux) Linux installation:

```bash
curl -sLO https://download.svcat.sh/cli/latest/linux/amd64/svcat
sudo chmod +x ./svcat
sudo mv ./svcat /usr/local/bin/
```

## Example Usage

As we have for a few other demos, let's set up a simple WordPress container with the database being provided by the broker. (I'm likely going to use this same database across several different reviews!)

First, let's look at the marketplace of services available using:

``` bash
svcat marketplace
```

This will return a list of classes and their plans that are available to install. While plans might mean a variety of things depending on the broker, in minibroker it's the version of helm chart that will be installed.

Since we can use MariaDB for the backend, and we see that the latest plan (version) available is 10-3-22, let's create one using:

``` bash 
svcat provision wp-mariadb --class mariadb --plan 10-3-22
```

This returns pretty immediately so we know that the creation is in progress. To check this progress we can use:

``` bash
svcat get instances
```

While still in process, the status column on the right will say `Provisioning` and running `kubectl get po` will show mariadb getting set up!

Once it's done, it'll say `Ready` and we can create a secret to bind with using 

```bash
svcat bind wp-mariadb
```

The secret can be viewed using:

```bash
kubectl get secret wp-mariadb -o yaml
```
At the top of the output, we can see the block of data that gets created. In it, there will be all the information needed to connect to our new database from an application (with each of the values being base64 encoded).


With these values, we can pass the right environment variables to our wordpress deployment using `secretKeyRef:` in the `env` section of the container spec.

Let's do that by creating a file called `wp-deploy.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: wp-deployment
  labels: 
    app: wordpress
spec: 
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template: 
    metadata: 
      labels: 
        app: wordpress
    spec: 
      containers: 
      - name: wordpress
        image: "docker.io/wordpress:5.7.0"
        imagePullPolicy: Always
        env: 
        - name: WORDPRESS_DB_HOST
          valueFrom:
            secretKeyRef:
              name: wp-mariadb
              key: host
        - name: WORDPRESS_DB_USER
          value: root
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wp-mariadb
              key: mariadb-root-password
        - name: WORDPRESS_DB_NAME
          valueFrom:
            secretKeyRef:
              name: wp-mariadb
              key: database
        ports: 
          - containerPort: 80
```

Then deploying it with:

```bash 
kubectl apply wp-deploy.yaml
```

One thing to note in the above YAML, we are using the root user and password because WordPress needs the elevated privileges when it starts up. There is likely a way to change this, but as minibroker is not really for production workloads, it's merely an inconvenience.

Next we can get our pod's name using:

```bash
kubectl get po
```
And use that to set up a port forward using (substituting in your pod's name):


``` bash
kubectl port-forward <pod name> 8080:80
```

Browse to http://localhost:8080/ to view your newly install wordpress with a database that was easy to configure! 


## Pros

- Easy to use
- Very flexible solution due to shared APIs
- Allows for good split in trust between platform maintainer and user

## Cons

- Few supported brokers
- API spec is overly complex for the currently available ecosystem

# Conclusion

The Open Service Broker API is an idea that I feel like hasn't gotten enough love from the Kubernetes community. There does need to be a way for platform maintainers to expose self-service creation of services and OSBA does a decent job of this. 

What I would like to see is a v3 of the spec that is simpler by taking advantage of Kubernetes features and Cloud Native methodologies.

As it stands, Service Catalog is definitely useful when building platforms for developers to use but might not be a great stand alone tool. 
