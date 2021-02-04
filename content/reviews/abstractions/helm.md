---
title: "Helm"
date: 2021-02-01
draft: false

github: "https://github.com/helm/helm"
homepage: "https://helm.sh/"
icon: "helm.png"
sponsors: ["CNCF"]
tagline_1: "The Kubernetes Package Manager"
tagline_2: ""

author: "Andrew Gracey"
author_bio: "Developer Advocate at SUSE, focusing on making Cloud Native development less painful"
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


### What privileges are needed to install / use

While the older Helm versions of Helm used a component called Tiller to manage installs, Helm 3 does it's work client side and uses the Kubernetes access controls. Due to this, different permissions will be required based on what the chart itself needs. 

For demo purposes, I'll be using my Cluster Admin to do the installs. 

### Installation Steps

On openSUSE, we can use zypper to install the Helm command:

```bash
sudo zypper in helm
```

The tool itself is a golang binary so it's also possible to [install by downloading](https://github.com/helm/helm/releases). 


### Sample

As this is a Developer tools blog, let's build a sample chart that runs a default wordpress instance and mysql then sets up the environment variables and routing. 

NOTE: I'm using the wordpress (and it's documentation) found in [Docker Hub](https://hub.docker.com/_/wordpress/) to know what configuration is available.

We start by creating some tempaltes to start with using:

```bash
helm create sample-wp
```

This will create a new folder with sample yaml at `./sample-wp`.

In this folder, there are two yaml files and two folders (and a hidden file `.helmignore`):

- Chart.yaml

This controls some basic metadata about the chart being created.

- values.yaml

This sets the default values used for templating. It can also be used for providing documentation for users! The contents of this file are displayed when a user runs `helm inspect values <your chart name>`. Please document your values, it makes everyone's life easier

- charts/ 

This folder provides a way to build [subcharts](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/) when your main chart gets too complicated. 

- templates/

This is where the magic happens. By default templates for a deployment, a service, some autoscaling magic, an ingress, a service account all get created, and a way to do automated testing all get created.


To start with, I'm going to delete each of these template defaults and start from scratch. 

Note: I'm not really a Wordpress developer or user so it's unlikely I'll create the best set up.

#### Database and it's Service

The first thing to do is create a mysql database instance. With this, we need a deployment and a service to let wordpress talk to it.

Note: Some of the needed values are Helm magic. I'm simplifying some of the indirection ()

Let's create a new file called `templates/mysql-deploy.yaml`: 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{.Chart.Name}}-database
  labels:
    helm.sh/chart: {{.Chart.Name}}-{{.Chart.Version}}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    app.kubernetes.io/name: {{.Chart.Name}}-wp
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: {{.Chart.Name}}-database
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{.Chart.Name}}-database
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}-database
        image: "{{ .Values.databaseImage.repository }}:{{ .Values.databaseImage.tag }}"
        imagePullPolicy: {{ .Values.databaseImage.pullPolicy }}
        env:
        - name: MYSQL_RANDOM_ROOT_PASSWORD
          value: "1"
        - name: MYSQL_USER
          value: {{.Values.mysql.user}}
        - name: MYSQL_PASSWORD
          value: {{.Values.mysql.password}}
        - name: MYSQL_DATABASE
          value: {{.Values.mysql.schema_name}}
        ports:
        - name: mysql
          containerPort: 3306
          protocol: TCP
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        emptyDir: {}
```


This will set up a mysql deployment with all the needed environment variables. It also sets up the right labels to allow for easy updating and rollback with helm. Typically this is abstracted with some code in `_helpers.tml`. 

For simplicity's sake, I'm using an EmptyDir volume instead of a PersistentVolume. Due to this, all data will be lost when the database pod restarts.

Next, we will add a service to allow other pods to access the database with a file called `templates/mysql-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-database
  labels:
    helm.sh/chart: {{.Chart.Name}}-{{.Chart.Version}}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    app.kubernetes.io/name: {{.Chart.Name}}-database
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: ClusterIP
  ports:
  - port: 3306
    targetPort: mysql
    protocol: TCP
    name: mysql
  selector:
    app.kubernetes.io/name: {{.Chart.Name}}-database
    app.kubernetes.io/instance: {{ .Release.Name }}
```

This will target the same pods that are created in the deployment template.

There are several template values defined above that need to have sane defaults applied. We can do that by changing the `values.yaml` to be (along with some that we can guess will be needed in the next section):

```yaml
# Image to use for WordPress
wpImage:
  repository: wordpress
  pullPolicy: IfNotPresent
  tag: 5.6.0
# Image to use for MySQL
databaseImage:
  repository: mysql
  pullPolicy: IfNotPresent
  tag: latest
mysql:
  user: wp_user
  password: SomeRandomPassword
  schema_name: wp_db

ingress:
  hostname: 127.0.0.1.omg.howdoi.website
```




#### Wordpress

Similar to MySQL, I created a file called `wp-deploy.yaml` to container the deployment manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-wp
  labels:
    helm.sh/chart: {{.Chart.Name}}-{{.Chart.Version}}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    app.kubernetes.io/name: {{.Chart.Name}}-wp
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: {{.Chart.Name}}-wp
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{.Chart.Name}}-wp
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}-wp
        image: "{{ .Values.wpImage.repository }}:{{ .Values.wpImage.tag }}"
        imagePullPolicy: {{ .Values.wpImage.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        env:
        - name: WORDPRESS_DB_HOST
          value: {{ .Release.Name }}-database.{{.Release.Namespace}}:3306
        - name: WORDPRESS_DB_USER
          value: {{.Values.mysql.user}}
        - name: WORDPRESS_DB_PASSWORD
          value: {{.Values.mysql.password}}
        - name: WORDPRESS_DB_NAME
          value: {{.Values.mysql.schema_name}}
```

As you can see we were able to reuse all the information we know about the database here to eliminate potential mis-configurations. (Imagine that your application was more than just a database and single server!)

For the Service, we will do the same with `wp-service.yaml`:

```yaml 
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-wp
  labels:
    helm.sh/chart: {{.Chart.Name}}-{{.Chart.Version}}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    app.kubernetes.io/name: {{.Chart.Name}}-wp
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app.kubernetes.io/name: {{.Chart.Name}}-wp
    app.kubernetes.io/instance: {{ .Release.Name }}
```


#### Ingress 

If you are running an ingress controller (Treafik if on K3s), you can set up an ingress as well. To do so you will need to use a DNS entry or a service like xip.io or omg.howdoit.website to fake a DNS! 

I'll be using omg.howdoi.website because it's a fun domain name.


To do this, I'll use an Ingress object in `wp-ingress.yaml`:

```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-wp
  labels:
    helm.sh/chart: {{.Chart.Name}}-{{.Chart.Version}}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    app.kubernetes.io/name: {{.Chart.Name}}-wp
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  rules:
  - host: {{ .Values.ingress.host | quote }}
    http:
      paths:
      - path: "/"
        pathType: Prefix
        backend:
          service: 
            name: {{ .Release.Name }}-wp
            port: 
              number: 8080
{{- end }}
```

What's a little more interesting about this, is that it uses an `if` statement to only create this object if the value is true (which we've set as the default).

#### Running

To install this, I ran:

```bash
helm upgrade --install wordpress-sample ./ --set ingress.host=wordpress-demo.192.168.1.12.omg.howdoi.website
```

I can see the Pods getting created when I run:

```bash
kubectl get pods
```

I can then browse to wordpress-demo.192.168.1.12.omg.howdoi.website and get the standard WordPress guided install page! Yay!




## Pros

- Industry standard
- Good security model 
- Can publish packages to public registry easily (Github Pages [make this free](https://medium.com/@mattiaperi/create-a-public-helm-chart-repository-with-github-pages-49b180dbb417))

## Cons

- Charts can become very complex
- Installation, Upgrades and Rollbacks are only single step (as opposed to the Operator Model which allows for a more scripted approach)


## Ideal Projects

Any project that has a lot of potential misconfigurations would likely benefit from helm's ability to give sane but editable defaults.

It's likely not worth creating a helm chart just for a Wordpress site, but it's very useful for anyone producing reusable components (platforms, databases, authentication, etc) who wants to simplify the process of installing their software.


# Conclusion

Helm is still the go to choice for most any team looking to distribute their application in an easy to consume way. If you are building an app that is more than one or two components or configuration options, you will likely want to package them into a chart. 