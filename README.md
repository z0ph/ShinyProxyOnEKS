# Efficiently build an enterprise-level Shiny platform based on Amazon EKS


Document version: v0.3

Date: 03/21/2020

Translated and Adapted from Chinese - Originaly posted [ShinyProxyOnEKS-China](https://github.com/MMichael-S/ShinyProxyOnEKS-China)

Scope of application:

* **AWS regions, this article takes AWS Ireland (`eu-west-1`) region as an example**
* It is recommended to enable a Linux server as an EKS cluster management server in AWS
* Will automatically create a new VPC for EKS cluster
* Amazon EKS `1.15` / eksctl `0.15.0` / kubectl `v1.15.10-eks-bac369` / AWS CLI `aws-cli/1.18.21`



## Shiny Introduction

R is an open source language and operating environment widely used for statistical analysis and drawing, and is also an excellent tool for statistical calculation and statistical drawing. [Shiny](https://shiny.rstudio.com/) is a product for R software launched by [Rstudio](https://rstudio.com/), which allows users to write without heavy code Easily build interactive Web applications directly from R, and provide access to people through the Internet in the form of Web applications, so that visitors can easily interact with data and analysis.
Industry experts, data scientists and analysts from all over the world have created many powerful web applications based on Shiny, such as the COVID-19 virus epidemic that everyone is most concerned about recently. Dr. Edward Parker from London School of Hygiene & Tropical Medicine uses Shiny Constructed an online kanban for multi-dimensional understanding and analysis of COVID-19 epidemic data.

![Source:https://shiny.rstudio.com/gallery/covid19-tracker.html](./img/shiny-COVID-19.png)
*Source: https://shiny.rstudio.com/gallery/covid19-tracker.html*

Many important functions are not provided in the open source version of Shiny, such as authentication, multiple Shiny process support, Shiny application performance monitoring, SSL-based secure connection, resource allocation control, etc. How to achieve enterprise-level safety certification? How to achieve failure recovery in seconds? How to achieve access support for massive concurrent users? These factors have caused users to encounter great obstacles in building an enterprise production environment for multi-user scenarios.

## ShinyProxy Introduction

[Open Analytics](https://www.openanalytics.eu/) developed [ShinyProxy](https://www.shinyproxy.io/) on top of the basic functions of the open source version of Shiny, providing a series of extended Enhanced features such as authentication and authorization, TLS protocol support, Shiny application containerization, and multi-concurrency support, etc. At the same time, ShinyProxy is a 100% open source project based on Apache license. ShinyProxy front-end uses mature enterprise-class Java framework [Spring Boot] (https://spring.io/projects/spring-boot) to complete user authentication and authentication of web applications and scheduling and management of back-end Shiny applications. Based on Docker technology, the terminal flexibly runs Shiny containers that encapsulate R applications.

![ShinyProxy Architecture](./img/shinyproxy-arch.png)
Caption: ShinyProxy architecture

Although ShinyProxy provides a fault-tolerant mechanism and high-availability design for Shiny applications, users will still face many different levels of risks and hidden risks when deploying in an actual enterprise-level environment, which will cause the user-oriented Shiny platform to fail to provide services and access.

* In case of network anomaly in the data center or network congestion or delay when users of large concurrent users visit;
* Such as the deployment server hardware and software failures, performance bottlenecks or downtime caused by maintenance work;
* If the server container environment is configured abnormally or suffered unexpected damage;
* Such as abnormal configuration or runtime abnormality of ShinyProxy


![ShinyProxy Failure Risk](./img/shinyproxy-risk.png)
Caption: ShinyProxy's failure risk

Based on the above factors, we still need to design a set of highly reliable and high-performance technology platforms and architectures for ShinyProxy to support the good operation of the entire platform. **In this article, we will focus on how to combine Amazon EKS and other mature services on the AWS platform to quickly build a high-quality Shiny platform with high security, high reliability, high flexibility, and cost optimization. **


## EKS Introduction

[Kubernetes](https://kubernetes.io/) is an open source system for containerized application deployment, expansion and automated management, and [Amazon Elastic Kubernetes Service](https://aws.amazon.com/ cn/eks/) (Amazon EKS) is a fully managed [Kubernetes](https://aws.amazon.com/kubernetes/) service that allows you to easily run Kubernetes on AWS without your own support or maintenance Kubernetes control level, so you can focus more on the code and functions of the application, and you can also take full advantage of all the advantages of open source tools in the community.

**Amazon EKS provided services in multiple AWS regions around the world in June 2018, and on February 28, 2020 in the AWS China (Beijing) region operated by Halo New Network and AWS China (Western Cloud Data) (Ningxia) The region is online, and the latest Kubernetes 1.15 version is provided in line with the global AWS region in the near future.**

* EKS runs Kubernetes management infrastructure across multiple AWS Availability Zones, automatically detects and replaces unhealthy control plane nodes, and provides on-demand upgrades and patching with zero downtime;
* EKS automatically applies the latest security patches to your cluster control plane, and works closely with the community to ensure that critical security issues are resolved before deploying new versions and patches to existing clusters;
* EKS runs upstream Kubernetes and is certified to be compatible with Kubernetes, so applications hosted by EKS are fully compatible with applications hosted by all standard Kubernetes environments.

## [1. Platform architecture and description](./doc/1-Architecture.md)



## [2. Amazon EKS creation](./doc/2-EKS-Create.md)



## [3. ShinyProxy deployment](./doc/3-ShinyProxy-Deploy.md)



## [4. Features and optimization](./doc/4-Optimization.md)


## Summary of the plan

After the above deployment, we verified the feasibility of ShinyProxy and Shiny applications running well on the Amazon EKS platform. At the same time, we can combine with other mature services of AWS and carry out in-depth optimization around security, reliability, flexibility, cost optimization and other aspects, so as to provide you and your customers with a high-quality Shiny platform. I hope you will build your own Shiny platform on AWS as soon as possible. If you encounter problems during deployment and use, you are also welcome to contact us in time. The team of AWS architects will be happy to help you solve technical problems and provide more optimizations. Suggest.


## Main reference materials:

### Shiny

https://shiny.rstudio.com/

### ShinyProxy

https://www.shinyproxy.io/

### Amazon Elastic Kubernetes Service

https://aws.amazon.com/cn/eks/

### Amazon Elastic Container Registry

https://aws.amazon.com/cn/ecr/

### eksctl

https://eksctl.io/


## License

This library is licensed under the MIT-0 License. See the LICENSE file.
