## 4. features and optimization

### 4.1 Flexible control of the node started by the Shiny application

In actual application scenarios, there is often such a demand. It is hoped that certain Shiny applications can run on designated nodes, such as selecting an EC2 service with a certain configuration.
We can achieve this through the parameter configuration provided by ShinyProxy and the "node selection" function provided by Kubernetes.


```
## Use the method of node group creation described above to start differently configured EC2 node groups, such as NG-UNMANAGED-C5-x and NG-UNMANAGED-C5-2x in the following examples, respectively representing the EC2 types used by the node group
## Add a custom node label to the node group with different configurations through kubectl label, such as the EC2 type/configuration used by the node, and the newly started node will also automatically add this label after enabling the label

kubectl label nodes -l alpha.eksctl.io/nodegroup-name=NG-UNMANAGED-C5-x NodeSize=c5.xlarge
kubectl label nodes -l alpha.eksctl.io/nodegroup-name=NG-UNMANAGED-C5-2x NodeSize=c5.2xlarge

## You can also add a corresponding label to the parameter file when creating a node group, such as:
    labels: {role: worker, NodeSize: c5.xlarge}

## Modify the configuration of the kubernetes section in the ShinyProxy configuration file application.yml
## Add the node-selector configuration, which can be the same as the label made in the above steps (Key=Value form)

  kubernetes:
    internal-networking: true
    url: http://localhost:8001
    namespace: shiny
    image-pull-policy: IfNotPresent
    image-pull-secret:
    node-selector: NodeSize=m5.xlarge
```

### 4.2 Shareable storage for Shiny apps

In the multi-user Shiny application environment, it is often encountered that multiple Shiny containers or even multiple nodes need to share and use the same storage. In the local data center, shared NAS storage is often used to meet the needs based on the NFS protocol. In the AWS platform, we can use [EFS service] (https://aws.amazon.com/cn/efs/) to achieve. The EFS service can provide a simple, scalable, fully managed and flexible NFS file system, and can be used in conjunction with other AWS cloud services.
For [Use EFS as persistent storage in EKS](https://aws.amazon.com/cn/premiumsupport/knowledge-center/eks-persistent-storage/), EKS provides [multiple ways](https://github.com/kubernetes-incubator/external-storage/tree/master/aws/efs), for example, can be used by the Container Storage Interface (CSI) driver in Pod and deployment. However, the container started by ShinyProxy does not support this method in Pod or Deployment. We need to pass the container-volumes parameter in [ShinyProxy Configuration](https://www.shinyproxy.io/configuration/) to allow the Shiny container to EFS storage can be used on the running node by way of mount.
It can be achieved in the following way, we will [complete the mounting of EFS on the EKS node when the EKS node is started](https://github.com/weaveworks/eksctl/blob/master/examples/05-advanced-nodegroups.yaml), and through the configuration of ShinyProxy to complete the path mapping and use of the subsequent Shiry container startup.

First refer to the document [Create EFS Storage] in the AWS region where the EKS cluster is located (https://docs.aws.amazon.com/zh_cn/efs/latest/ug/creating-using.html), and complete [Security Group And mount point settings](https://docs.aws.amazon.com/zh_cn/efs/latest/ug/mounting-fs.html), record the EFS file system ID after successful creation.

```
## To enable the node to mount EFS storage, we will add three commands to the "preBootstrapCommands" configuration section of the configuration file of the node group creation process to complete the automatic mounting of EFS during the node startup process
## Pay attention to modify the EFS service ID in the second instruction
preBootstrapCommands:
      -'sudo mkdir -p /mnt/data/'
      -'sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport EFS file system ID.efs.cn-northwest-1.amazonaws.com.cn :/ /mnt/data/'
      -'sudo chmod -R 777 /mnt/data'

```

```
## In the ShinyProxy application.yml configuration file, enable automatic mounting for the corresponding Shiny container
## Note the consistency of the paths in container-volumes

container-volumes: ["/mnt/data:/root/Shiny_seurat/Users/data"]

```

### 4.3 Automatic scaling for real-time load

Provides a variety of automatic scaling features and configuration methods in the Amazon EKS cluster, which can support multiple types of automatic scaling of Kubernetes, such as the expansion of the number of nodes (Cluster Autoscaler), the horizontal expansion of the number of Pods (Horizontal Pod Autoscaler) and Pod configuration Vertical Scaling (Vertical Pod Autoscaler).
 Combining the features of ShinyProxy, we can add the Cluster Autoscaler function to the current cluster of Amazon EKS, so that EKS can achieve a flexible and flexible according to various factors such as the number of concurrent user access, the number of Shiny applications running, and the resource requirements of Shiny applications. And cost-effective cluster platform. Other automatic scaling functions can also be configured according to the requirements by referring to [documentation](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/autoscaling.html). Due to space constraints, you can refer to [EKS Cluster Autoscaler](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/cluster-autoscaler.html) for corresponding configuration and testing.
In addition, after the configuration is completed, the number of each node group in EKS can also be managed at any time through eksctl as needed.

```
## If the number of original nodes is adjusted from 2 to 3
eksctl scale nodegroup --cluster EKS cluster name --name node group name --region=cn-northwest-1 --nodes 3

```

### 4.4 Provide higher authentication features

In the previous test deployment, the Shinyproxy configuration uses the Simple authentication mode. The user name and password are written in the configuration file in clear text, which has great security risks. It is also difficult to maintain and expand in a multi-user environment. In fact, ShinyProxy provides support for multiple user authentication modes, including LDAP, Kerberos, Keycloak, OpenID Connect, Social Authentication, Web Service Based Authentication and other modes. It is recommended that in the production environment, user authentication and authentication methods with higher security can be selected and improved according to the situation.
[AWS Directory Service](https://docs.aws.amazon.com/zh_cn/directoryservice/latest/admin-guide/what_is.html) is also a good enterprise-level choice for users. AWS Directory Service provides multiple ways to use Amazon Cloud Directory and Microsoft Active Directory (AD) with other AWS services. Also available through AWS [Active Directory Connector](https://docs.aws.amazon.com/zh_cn/directoryservice/latest/admin-guide/directory_ad_connector.html)
Redirect directory requests to the existing Microsoft Active Directory locally without having to cache any information in the cloud. In the AD directory, ShinyProxy can store information about users and groups. Use the corresponding LDAP configuration section in the ShinyProxy configuration to complete the corresponding configuration.

```
proxy:
  ldap:
    url: ldap://ldap.xxxxx.com:389/dc=example,dc=com
    ...
```

### 4.5 Using AWS Application Load Balancer to Improve Platform High Availability

AWS Elastic Load Balancing supports three types of load balancers: Application Load Balancer, Network Load Balancer, and Classic Load Balancer. In the previous test deployment, we deployed using the AWS Classic load balancer. AWS Classic load balancer is the early load balancer service of AWS. It will be gradually replaced by the new AWS application load balancer or network load balancer service. The new service provides better application characteristics and performance.
Using the application load balancer at the same time, the ShinyProxy Pod can be set to support multiple copies of highly available deployments, further improving the platform's high availability characteristics and greatly reducing the recovery time when an exception occurs.

You can refer to [ALB Ingress Controller on Amazon EKS](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/alb-ingress.html) Use AWS Application Load Balancer for ShinyProxy deployment .
The following modifications are required for the configuration process of ShinyProxy.

```
## Edit the sp-service.yaml file and modify it to the following

kind: Service
apiVersion: v1
metadata:
  name: shinyproxy
  namespace: default
spec:
  ports:
    -port: 80
      targetPort: 8080
      protocol: TCP
  type: NodePort
  selector:
    run: shinyproxy
```

```
## Create a new sp-shinyingress.yaml file with the following content:
## Set the path of ALB health check to /login
## Change the type of ALB target group to IP (default is Instance),
## ALB will act directly on Pod. After setting sticky session support, it can support high availability deployment of ShinyProxy Replica >= 2
## ALB Annotations can be used to modify ALB load balancer attributes, please refer to [Related Documents](https://docs.aws.amazon.com/zh_cn/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-type)

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: "shinyproxy-ingress"
  namespace: "default"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-group-attributes: stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=3600
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=1800
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    alb.ingress.kubernetes.io/healthcheck-path: /login
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '20'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    alb.ingress.kubernetes.io/target-type: ip

  labels:
    run: shinyproxy
spec:
  rules:
    -http:
        paths:
          -path: /*
            backend:
              serviceName: "shinyproxy"
              servicePort: 80
```

### 4.6 Significant cost savings using Spot instances

AWS provides a wealth of EC2 usage and payment models. By using Amazon EC2 Spot instances in EKS, you can use unused EC2 capacity in the AWS cloud. Compared with the price of on-demand instances, using Spot instances can enjoy up to 90 % Discount, which greatly reduces platform operating costs.
Spot instances are suitable for a variety of stateless, fault-tolerant or flexible applications. During the testing phase of the Shiny platform or in appropriate production scenarios, if you accept the short-term abnormal state caused by the interruption of the node, you can pass the following Way to enable EC2 Spot instances in a node group. For details, please refer to [Documents](https://aws.amazon.com/cn/blogs/compute/run-your-kubernetes-workloads-on-amazon-ec2-spot-instances-with-amazon-eks/) and [The corresponding configuration method of eksctl](https://eksctl.io/usage/spot-instances/).

```
## In the configuration file of the node group, add the following content. The EC2 type and the corresponding quantity can be customized as required.
    instancesDistribution:
      maxPrice: 1
      instanceTypes: ["c5.xlarge"]
      onDemandBaseCapacity: 0
      onDemandPercentageAboveBaseCapacity: 0
      spotInstancePools: 2

```

### 4.7 Build a complete operation, maintenance and monitoring system

Amazon EKS provides a complete monitoring and operation and maintenance system native to AWS. In addition, it also integrates well with mainstream Kubernetes management tools and monitoring tools in the open source ecosystem. You can refer to **[Common Operation and Maintenance and Monitoring Methods](https:/ /github.com/MMichael-S/ShinyProxyOnEKS-China/blob/master/doc/III-Monitor.md)** Deploy to build a complete operation and maintenance system for Amazon EKS and Shiny platform. For other deployments such as Kubernetes Metrics Server, Prometheus, Grafana, etc., please refer to: [Prometheus Control Level Indicators](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/prometheus.html), [Install Kubernetes Metrics Server](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/metrics-server.html).

![EKS Dashboard](https://github.com/MMichael-S/ShinyProxyOnEKS-China/blob/master/img/dashboard.png)
Photo caption: EKS Dashboard management interface


## License

This library is licensed under the MIT-0 License. See the LICENSE file.