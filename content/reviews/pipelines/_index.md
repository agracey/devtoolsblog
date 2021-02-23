---
title: "pipelines"
date: 2020-12-04T08:48:59-08:00
draft: true

realtitle: "CI/CD Pipelines"
icon: wifi_protected_setup

---



# Why should I care about CI/CD?

CI/CD stands for Continuous Integration and Continuous Delivery (or Deployment) and forms the basis of the DevOps software development methodology. 

While typically talked about together, each term is a separate idea:
- Continuous Integration is the idea that all of code changes get merged into the main branch of your repository instead of staging changes in an "integration branch"
- Continuous Delivery builds on this by saying that instead of having releases be on a schedule (weekly for example), the deliverable is released every time it meets some criteria. This likely happens 10-1000 times a day. 
- Continuous Deployment is a continuation of these for service providers where the end stage is to actually roll out new versions of the code automatically (and likely roll back on any errors)


These ideas together give an amazingly agile way of building complex software. Since the change between each version is tiny, any breakages or errors can more easily be traced to their source. It also means the end user of the software can get new value sooner! 

This all comes at a cost though... It's obviously not possible to manually test, build, and deploy ever single version of the code so we need to automate the process. Due to this, an entire industry has been created around this problem and each solution approaches it in a different way.

As these processes are central to building your software, it's important to pick a solution that works the way you need it to. I've selected a few of the most popular (or novel) choices in the industry currently in the hopes of making the selection process less tedious. 

For some discussion on requirements and best practices check out [this article from Atlassian.](https://www.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery-vs-deployment)

