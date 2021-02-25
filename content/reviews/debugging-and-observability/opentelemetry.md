---
title: "Opentelemetry"
date: 2020-12-07T08:05:22-08:00
draft: true

github: "https://github.com/open-telemetry"
homepage: "https://opentelemetry.io"
icon: opentelemetry.png
sponsors: []
tagline_1: "OpenTelemetry makes robust, portable telemetry a built-in feature of cloud-native software."
tagline_2: ""


---

OpenTelemetry is a set of specifications, tools, and best practices for instrumenting code for observability. It was formed by OpenTracing and OpenCensus joining together and donating their work to the CNCF as a sandbox project.

# What is Observability 

Observability is all about exposing the inner structure of how data flows through a system to the people having to maintain the system. This can be exceedingly difficult in cloud native architectures as the data path can be across several components (likely maintained by several teams). When something goes wrong in the system, it's helpful to have ways of looking back at the path data took and the system state as errors occurred.

## Metrics

Metrics provide point-in-time snapshots of different measurements available to the application. These can be "consumables" (such as disk space, memory, cpu, file descriptors, etc...), or rates of events (such as requests in the last 15 seconds, or cache misses in the last minute, etc...). 

By sampling these over time using a tool like Prometheus, you can give a really valuable insight into application health

## Logging

Logs are a linear output of different points reached in your code. They can be useful for outputting system state at certain times. 

It used to be popular to output different streams of logs to different files but with the short-term nature of application lifecycles, it's much better to output structured logging to [standard out and standard error](https://www.howtogeek.com/435903/what-are-stdin-stdout-and-stderr-on-linux/) and let Kubernetes or Docker store it!

## Tracing

Tracing is a comparatively new idea here. It allows you to see how a request or event propagates through the entire system. 

Traces are built up of "spans" which can relate to each other in different ways. For example, you could have a parent span that tracks the duration of an event created from a button click which would track each of the requests made as child spans. Those child spans would then have their own child spans internal to the API (for example an auth middleware). 

# Review




## Prior knowledge needed

- Programming in a supported modern language
- Some way to run containers and access them (Docker, Podman, Kubernetes, etc)

## Sample Instrumentation

I apologize in advance that these instructions are comparatively long but there are several moving pieces that need to be in place first to make it all work.

### OpenTelemetry Collector

I'm actually going to skip using the collector for this example since it doesn't add anything to the understanding of the ideas being demonstrated. For any real world use, I would suggest looking into it!

I debated this for a while so if you feel like this is a mistake please let me know and I will adapt the example to use it.


### Zipkin

I'll also install Zipkin over Jaeger because it's simpler. Jaeger does offer a lot more features and a better UI but for this example, I don't need the complexity.


``` bash
docker run -d --name zipkin \
  -p 9411:9411 \
  openzipkin/zipkin
```

### Prometheus

At the time of writing this, Prometheus seemed to be most popular choice for metrics collection (as well as being a CNCF Graduated project). 

Prometheus can be installed by creating a configuration file called `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
scrape_configs:
- job_name: prometheus
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets:
    - localhost:9090
- job_name: my_sample_app
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets:
    - localhost:3000
```

This file will monitor itself and our non-yet-existing sample app (hosted at port 3000 TODO this might be wrong?).  

We can then start the server with: 

``` bash
docker run -p 9090:9090  \
  -v `pwd`/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

Browsing to `http://127.0.0.1:9090` will give me the Prometheus UI. We will come back to this once we have something worth monitoring!

### Application Instrumentation

For this example, I'll set up a basic application express application that gets the weather for a provided address, "caches" it in sqlite, then returns the current temperature.

First, let's set up a new node project with:

``` bash
npm init -y
npm i express axios sequelize sqlite3
```

Then write a sample application to `index.js`:

``` js

```

Since I don't want to deal with babel set up, this is all the commonjs to have a `/weather/:address` endpoint that gets the weather for an address!

#### OpenTelemetry Libraries

The installation of the client library will be language specific. For my use case I'll be using the [node.js libraries](https://github.com/open-telemetry/opentelemetry-js).

```bash
npm i @opentelemetry/core @opentelemetry/api @opentelemetry/tracing @opentelemetry/node @opentelemetry/metrics @opentelemetry/exporter-prometheus @opentelemetry/exporter-zipkin @opentelemetry/plugin-http @opentelemetry/plugin-https @opentelemetry/plugin-express 
```

This loads all of the dependencies needed (as well as some that will auto-instrument requests for us!)



## Pros

- Open standards with the implementations and market buy-in to succeed
- Auto-instrumentation is awesome!
- Large base of supported languages

## Cons

- Requires code additions to gain most value

# Conclusion


