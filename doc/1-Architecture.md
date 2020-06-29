## 1. Platform Architecture and Description

In this solution, we will mainly use the following services:

* AWS Identity and Access Management (IAM): used for identity authentication and permission management on the AWS platform
* Amazon Elastic Compute Cloud (EC2): used for EKS management server and working nodes in EKS ([Node](https://kubernetes.io/docs/concepts/architecture/nodes/))
* Amazon Elastic Kubernetes Service (EKS): used for container scheduling and management of ShinyProxy and Shiny applications;
* Amazon Elastic Container Registry (ECR): Mirror warehouse for storing ShinyProxy and Shiny containers;
* Elastic Load Balancing (elastic load balancer): used to receive access user requests and forward it to the back-end ShinyProxy component;
* Amazon CloudWatch: used for monitoring and log management of Amazon EKS service and working nodes in EKS
* Amazon Elastic File System (EFS): used to store persistent shared data required by Shiny applications;


![ShinyProxy On EKS Architecture](https://github.com/MMichael-S/ShinyProxyOnEKS-China/blob/master/img/ShinyOnEKS-Arch.png)
Caption: ShinyProxy On EKS architecture

**The construction process of the entire platform will be divided into three steps:**

* Create Amazon EKS service
* Deploy ShinyProxy
* Further optimized configuration around Shiny application scenarios

Before starting the creation and deployment of the Amazon EKS service, please refer to **[Preparation](https://github.com/MMichael-S/ShinyProxyOnEKS-China/blob/master/doc/I-Preparation.md)* * And **[Management Machine Configuration](https://github.com/MMichael-S/ShinyProxyOnEKS-China/blob/master/doc/II-ManagementServer.md)** Complete the preparatory work.


## License

This library is licensed under the MIT-0 License. See the LICENSE file.
