---
title: "Opentelemetry"
date: 2020-12-07T08:05:22-08:00
draft: false

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

Tracing is a comparatively new idea here. It allows you to see how a user action or event propagates through the entire system by allowing components to let each other know the parent span that originated the request.

Traces are built up of "spans" which can relate to each other in different ways. For example, you could have a parent span that tracks the duration of an event created from a button click which would track each of the requests made as child spans. Those child spans would then have their own child spans internal to the API (for example an auth middleware). 

For example, for a simple three level architecture:

![Basic Three Level Architecture with External Auth](/screenshots/span_example_arch.png)

We have some idea of the relationship between components but it might be hard to gauge relative load or diagnose where potential bottlenecks might be. With tracing we can find the relationships more quickly because you see a call stack like view:

![Example Of Spans across Components](/screenshots/span_example.png)

Now we can see that each click might generate two database calls and a call to the external authentication provider. From my rough sketch, you might also assume that some of the potential slow down is actually in view layer since there's a lot of space on the right where there's nothing under "Redraw Comment View".

The ability to pass context between components to get a full stack view of each call is very useful!

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
  scrape_timeout: 5s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets:
    - localhost:3001
```

This file will monitor itself and our non-yet-existing sample app (hosted at port 3000 TODO this might be wrong?).  

We can then start the server with: 

``` bash
docker run -p 9090:9090  \
  -v `pwd`/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

Browsing to `http://127.0.0.1:9090` will give me the Prometheus UI. We will come back to this once we have something worth monitoring!

### Application Code

For this example, I'll set up a basic application express application that gets the weather for a provided address, "caches" it in sqlite, then returns the current temperature.

First, let's set up a new node project with:

``` bash
npm init -y
npm i express axios sequelize sqlite3
```

Then write a sample application to `index.js`:

``` js
const WEATHER_API_KEY = `Generate for free at https://home.openweathermap.org/` 

const express = require('express')
const app = express()
const axios = require('axios')
const { Sequelize, Model, DataTypes } = require('sequelize')

const sequelize = new Sequelize('sqlite::memory:')

class Temp extends Model {}
Temp.init({temp: DataTypes.STRING, addr: DataTypes.STRING}, {sequelize, modelName: 'temp'})
sequelize.sync()

const getTempsFromCache = async (addr) => (Temp.findAll({where:{addr}}))

const getTempFromAPIandCache = async (addr) =>{
  const resp = await axios.get(`https://api.openweathermap.org/data/2.5/weather?q=${addr}&appid=${WEATHER_API_KEY}`)
  return Temp.create({temp: resp.data.main.temp, addr})
}


app.get('/weather/:addresses', async (req, res)=>{
  try {
    const addresses = req.params.addresses.split('+')

    const ret = []

    for(let i = 0; i<addresses.length; i++){
      const addr = addresses[i]
      const past = await getTempsFromCache(addr)
      const current = await getTempFromAPIandCache(addr)
      ret.push( {addr, temps:[current, ...past].map(({temp})=>(parseInt(temp)))})
    }

    res.send(ret) 
  } catch (e){ 
    console.log(e)
    res.send({error: e}) 
  }
})

app.listen(3000)
```

You can test this by running 

``` bash
node index.js
```
Then browsing to `localhost:3000/weather/12345`


Since I don't want to deal with babel set up, this is all the commonjs to have a `/weather/:address` endpoint that gets the weather for an address!

### Tracing Auto Instrumentation 

The installation of the client library will be language specific. For my use case I'll be using the [node.js libraries](https://github.com/open-telemetry/opentelemetry-js).

```bash
npm i @opentelemetry/core @opentelemetry/api @opentelemetry/tracing @opentelemetry/instrumentation @opentelemetry/node @opentelemetry/metrics @opentelemetry/exporter-prometheus @opentelemetry/exporter-zipkin @opentelemetry/plugin-http @opentelemetry/plugin-https @opentelemetry/plugin-express 
```

This loads all of the dependencies needed (as well as some that will auto-instrument requests for us!)

To wire up some basic tracing, we can create a file called `tracer.js`:

``` js
const  opentelemetry = require('@opentelemetry/api')
const { NodeTracerProvider } = require('@opentelemetry/node')
const { SimpleSpanProcessor } = require('@opentelemetry/tracing')
const { ZipkinExporter } = require('@opentelemetry/exporter-zipkin')
const { registerInstrumentations } = require("@opentelemetry/instrumentation")
const provider = new NodeTracerProvider({})

provider.addSpanProcessor(
  new SimpleSpanProcessor(
    new ZipkinExporter({serviceName: 'my-sample-app'})
  )
)

provider.register()
registerInstrumentations({
  tracerProvider: provider,
})

opentelemetry.trace.setGlobalTracerProvider(provider)
```

Then we can run the application with the `-r` flag to use this new file as a global requirement:

``` bash 
node -r tracer.js index.js
```

Now, we can run a few queries against this app:

``` bash 
curl http://127.0.0.1:3000/weather/12345+67890+24680+89765+54321
```

Then browse to `http://127.0.0.1:9411/zipkin/` and click `RUN QUERY` (at the top right). This should show the recent span generated by this request.

If you click on `SHOW`, it'll give you a view of the "span-tree" generated:

TODO: generate screenshot


If we look at this, we see some inefficiency in the code we wrote very clearly since the requests are happening sequentially. 

Let's quickly refactor this code and replace the for loop with some async and promise magic:

``` js
const ret = await Promise.all(addresses.map( async (addr)=>{
  const past = await getTempsFromCache(addr)
  const current = await getTempFromAPIandCache(addr)
  return {addr, temps:[current, ...past].map(({temp})=>(parseInt(temp)))}
}))
```

This will run the requests in parallel then return all the same data as before. To see this, run the same test as before:

``` bash 
curl http://127.0.0.1:3000/weather/12345+67890+24680+89765+54321
```

And then click `RUN QUERY` and `SHOW` on the new trace. You should now see that the requests were performed in parallel!

TODO: screenshot of after


### Metrics Collection

Next let's set up a metrics exporter for api requests and temperatures requested.

We can do this by adding the following code at the top of index.js:

``` js
const { MeterProvider }  = require('@opentelemetry/metrics')
const { PrometheusExporter } = require('@opentelemetry/exporter-prometheus')

const exporter = new PrometheusExporter({ startServer: true, port: 3001 })
const meter = new MeterProvider({exporter, interval: 1000}).getMeter('example-prometheus')

const requestCount = meter.createCounter("request_count")
const tempsRequested = meter.createCounter("temp_req_count")
```

We can then add:

``` js
app.use((req,res,next)=>{requestCount.add(1); next()})
```
above `app.get(...)` to count all of the requests.

We can also change `getTempFromAPIandCache` to be:

``` js
const getTempFromAPIandCache = async (addr) =>{
  tempsRequested.add(1)
  const resp = await axios.get(`https://api.openweathermap.org/data/2.5/weather?q=${addr}&appid=${WEATHER_API_KEY}`)  
  return Temp.create({temp: resp.data.main.temp, addr})
}
```

This will count all of the times we request a temp from `openweathermap.org`. 

Once you call the API a few times, browse to `http://127.0.0.1:9090` and input the expression:

``` promql
request_count
```

This will show you how many times the api had been called the last time prometheus queried the metrics. This timing is controlled by the configuration yaml we wrote while installing prometheus.

We can do the same with:

``` promql
temp_req_count
```

### Logging

At the time of my writing this, the logging portion of OpenTelemtry was not finished yet. There are several drafts of how this would be done and it looks really good in my opinion! I'll update this to include logging as soon as I hear that there are libraries published to leverage.


## Pros

- Open standards with the implementations and market buy-in to succeed
- Auto-instrumentation is awesome!
- Large base of supported languages

## Cons

- Requires code additions to gain most value
- A bit new so some libraries are still in flux

# Conclusion

OpenTelemetry has enough other projects backing it that I don't see it going away. It solves a very real need and can make debugging problems after they happen in production possible again without needing to build crazy systems of quarantining pods that are acting up.

Done right, it can also be a good way to bridge the gap between the developer and operator by giving a common touch point for both teams. Developers want good feedback when something goes wrong in production and operators want early warning before those things go wrong. 

If you are building an application in a cloud native way, you should be instrumenting your code. OpenTelemetry gives an easy way to go about that!
