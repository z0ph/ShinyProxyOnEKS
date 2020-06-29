## 3. ShinyProxy deployment

ShinyProxy natively supports three container back-end platforms, the stand-alone version of Docker, Docker Swarm cluster, and Kubernetes cluster. In this step, we will complete the deployment of ShinyProxy on the EKS Kubernetes platform.

### 3.1 Amazon ECR configuration

[Amazon Elastic Container Registry](https://docs.aws.amazon.com/en_us/AmazonECR/latest/userguide/what-is-ecr.html) (Amazon ECR) is a managed AWS Docker image warehouse service, safe , Scalable and reliable. By working with AWS IAM services, Amazon ECR can restrict access to specific users or Amazon EC2 instances, and you can use the Docker CLI to push, pull, and manage images. You can refer to [Create ECR Repository for Container Images via Console](https://docs.aws.amazon.com/zh_cn/AmazonECR/latest/userguide/getting-started-console.html) and [Amazon ECR CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ecr/index.html).
If the relevant container has been stored in the local or other three-party mirror warehouse, this step can be ignored.

```
## Create a container image ECR repository via AWS CLI
REGION_EKS=cn-northwest-1
export AWS_DEFAULT_REGION=$REGION_EKS

## Create three ECR repositories
aws ecr create-repository \
    --repository-name shiny-application \
    --image-scanning-configuration scanOnPush=true

aws ecr create-repository \
    --repository-name kube-proxy-sidecar \
    --image-scanning-configuration scanOnPush=true

aws ecr create-repository \
    --repository-name shinyproxy-application \
    --image-scanning-configuration scanOnPush=true

## Log into the ECR service (the following commands do not need to be modified and executable, pay attention to retain the $ symbol and brackets)
## Successful execution will return "Login Succeeded" message
$(aws ecr get-login --no-include-email --region cn-northwest-1)
```

### 3.2 Shiny test application

In this part, we will create a simple Shiny test application for ShinyProxy. In order to simplify the compilation process of the Shiny application, we directly use Rocker's official shiny container as a test application in this article. You can also choose the R application container for testing, such as the sample Shiny application of [Rstudio](https://github.com/rstudio/shiny-examples/blob/master/docker/Dockerfile), or the current R Apply containerization and encapsulate with Shiny for actual testing. If you already have a Shiny application container ready, this step can be ignored.


```
## Search Shiny Container
docker search shiny

## Pull the Shiny container
docker pull rocker/shiny

## Simple test, such as starting Shiny on port 80 (unused ports on EC2), you need to enable the EC2 security group settings accordingly
sudo docker run -it -p 80:3838 rocker/shiny
```

Access the EC2 public network IP address and corresponding port through a browser. If the Shiny application normally displays the "Welcome to Shiny Server!" page.

If you use Dockerfile to create a Shiny container, or use an existing Shiny container, you should annotate the start command at the end of the Dockerfile, re-create the docker build and then push it to the Amazon ECR image warehouse, and write the start command of the Shiny container accordingly Shinyproxy's configuration file for subsequent Shinyproxy to initiate the correct call.

### 3.3 ShinyProxy configuration

In this step, we will refer to [Example Configuration of OpenAnalytics](https://github.com/openanalytics/shinyproxy-config-examples/tree/master/03-containerized-kubernetes) to complete ShinyProxy and kube-proxy-sidecar deploy.


```
## Download the sample configuration for OpenAnalytics
cd ~/download
git clone https://github.com/openanalytics/shinyproxy-config-examples.git
cd ~/download/shinyproxy-config-examples/03-containerized-kubernetes

vi kube-proxy-sidecar/Dockerfile
## Modify the content of the Dockerfile file in the kube-proxy-sidecar directory to:

FROM alpine:3.6
ADD https://share-aws-nx.s3.cn-northwest-1.amazonaws.com.cn/shiny/kubectl1.7.4 /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl
EXPOSE 8001
ENTRYPOINT ["/usr/local/bin/kubectl", "proxy"]

```

Modify ShinyProxy's Dockerfile file to update ShinyProxy to the latest stable version or other download sources. Please check [ShinyProxy version information](https://www.shinyproxy.io/downloads/) regularly.

```
FROM openjdk:8-jre

RUN mkdir -p /opt/shinyproxy/
RUN wget https://share-aws-nx.s3.cn-northwest-1.amazonaws.com.cn/shiny/shinyproxy-2.3.0.jar -O /opt/shinyproxy/shinyproxy.jar
COPY application.yml /opt/shinyproxy/application.yml

WORKDIR /opt/shinyproxy/
CMD ["java", "-jar", "/opt/shinyproxy/shinyproxy.jar"]

```


Before creating the ShinyProxy container and pushing it, you need to make some corresponding edits to its configuration file application.yml to adapt to the current environment. The meaning of the parameters involved can be referred to: [Shinyproxy configuration parameter description](https://www.shinyproxy.io/configuration/).

**Notice:**

* Modify the AWS account in the configuration file example to your account information;
* At present, the simple authentication mode of Shinyproxy is used, and the user name and password are modified according to the actual situation.
* ShinyProxy backend can run containers, can come from ECR mirror warehouse, can also come from other mirror warehouse or Internet container
* Note that the start command path matching each Shiny container is consistent with the information in the original Dockerfile
* ShinyProxy uses the Spring Boot framework, [related parameter settings](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html) will affect its running configuration. For example, the size limit of the uploaded file in the Shiny container is only 1MB or 10MB by default. You can increase the limit by setting the spring section in the configuration file. You also need to set the corresponding value in the Shiny application.


```
cd ~/download/shinyproxy-config-examples/03-containerized-kubernetes/shinyproxy-example

vi application.yml

proxy:
  port: 8080
  authentication: simple
  admin-groups: admins
  users:
  -name: admin
    password: Admin@123
    groups: admins
  -name: guest
    password: Guest@123
    groups: guest
  container-backend: kubernetes
  container-wait-time: 300000
  heartbeat-rate: 10000
  heartbeat-timeout: 300000
  kubernetes:
    internal-networking: true
    url: http://localhost:8001
    namespace: shiny
    image-pull-policy: IfNotPresent
    image-pull-secret:
  specs:
  -id: 00_demo_shiny_application
    display-name: Simple Shiny Application Demo
    description: Simple Shiny Application Demo
    container-cmd: ["sh", "/usr/bin/shiny-server.sh"]
    container-image: <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/shiny-application:v1
    access-groups: [admins, guest]
  -id: 01_hello_shiny_application
    display-name: Hello Application
    description: Application which demonstrates the basics of a Shiny app
    container-cmd: ["R", "-e", "shinyproxy::run_01_hello()"]
    container-image: openanalytics/shinyproxy-demo
    access-groups: [admins, guest]

spring:
  servlet:
    multipart:
      max-file-size: 100MB
      max-request-size: 100MB

logging:
  file:
    shinyproxy.log
```

### 3.4 Container push to Amazon ECR

To complete the overall deployment, we need to push three containers to the Amazon ECR mirror warehouse, including:

* ShinyProxy container
* kube-proxy-sidecar container (for the proxy function of ShinyProxy)
* Shiny test application container

When marking the upload of the container image, please pay attention to replace the AWS account with your account information.
The container label in ECR can be used to release version control of different containers multiple times. See: [Push Image] (https://docs.aws.amazon.com/zh_cn/AmazonECR/latest/userguide/docker-push-ecr-image.html)

```
## Mark and push Shiny test application container to ECR service
docker tag rocker/shiny:latest <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/shiny-application:v1
docker push <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/shiny-application:v1

## Create, mark and push kube-proxy-sidecar container
cd ~/download/shinyproxy-config-examples/03-containerized-kubernetes/kube-proxy-sidecar
docker build -t <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/kube-proxy-sidecar:v1.
docker push <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/kube-proxy-sidecar:v1

## Create, mark and push containers to ECR services, the tags can be customized
cd ~/download/shinyproxy-config-examples/03-containerized-kubernetes/shinyproxy-example
docker build -t <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/shinyproxy-application:v1.
docker push <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/shinyproxy-application:v1

```

### 3.5 ShinyProxy deployment

The sp-authorization.yaml file does not need to be modified.

Edit the sp-service.yaml file so that EKS automatically creates a load balancer for easy access after deployment.
Change the type to LoadBalancer, where the port parameter is the port used by the subsequent load balancer.

```
cd ~/download/shinyproxy-config-examples/03-containerized-kubernetes

vi sp-service.yaml

kind: Service
apiVersion: v1
metadata:
  name: shinyproxy
spec:
  type: **LoadBalancer**
  selector:
    run: shinyproxy
  ports:
  -protocol: TCP
** port****:**** ****80**
    targetPort: 8080
    nodePort: 32094
```

Edit the sp-deployment.yaml file and modify the contents to correspond to the container names and labels that have been published in the Amazon ECR mirror warehouse in the current environment. Note that you need to modify the AWS account number as your account information.

```
cd ~/download/shinyproxy-config-examples/03-containerized-kubernetes

vi sp-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: shinyproxy
  namespace: default
spec:
  selector:
    matchLabels:
      run: shinyproxy
  replicas: 1
  template:
    metadata:
      labels:
        run: shinyproxy
    spec:
      containers:
      -name: shinyproxy
        image: <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/shinyproxy-application:v1
        imagePullPolicy: IfNotPresent
        ports:
        -containerPort: 8080
      -name: kube-proxy-sidecar
        image: <AWS account ID>.dkr.ecr.cn-northwest-1.amazonaws.com.cn/kube-proxy-sidecar:v1
        imagePullPolicy: IfNotPresent
        ports:
        -containerPort: 8001
      imagePullSecrets:

```

## Use kubectl to complete the deployment
`kubectl apply -f sp-authorization.yaml`
`kubectl apply -f sp-deployment.yaml`
`kubectl apply -f sp-service.yaml`

## If the sp-deployment.yaml file is modified later, you can re-apply to apply the new content
`kubectl apply -f sp-deployment.yaml`

## You can use the following command to view the deployment of ShinyProxy. Under normal circumstances, the Running status will be displayed soon.
`kubectl get pod -n shiny --watch`

## The deployment process will automatically create an AWS load balancer for access to ShinyProxy
## Use the following command to get the access address link of AWS load balancer information in the EXTERNAL-IP column
## The load balancer has a process of creating and taking effect for about a few minutes. You can confirm the status of the load balancer through the AWS console before accessing
`kubectl get svc`


When accessing the load balancer address and port, the login interface of ShinyProxy can be displayed normally. Enter the user name and password information configured previously to display the ShinyProxy management interface, and click the existing Shiny application to start them. At this point, the ShinyProxy platform has successfully run on the Amazon EKS service.

![ShinyProxy main interface](./../img/ShinyProxy-GUI.png)
Photo caption: ShinyProxy main interface

![Run interface of Shiny application](./../img/ShinyProxy-Shiny-GUI.png)
Photo caption: Shiny application running interface

## License

This library is licensed under the MIT-0 License. See the LICENSE file.