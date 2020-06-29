## 2. Amazon EKS creation

[Amazon EKS cluster](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/clusters.html) contains two main parts: Amazon EKS control plane and Amazon EKS worker thread node. The Amazon EKS control plane consists of control plane nodes running Kubernetes software (such as etcd) and a Kubernetes API server. The control plane is managed by AWS. To provide AWS users with higher security and a better user experience, each Amazon EKS cluster control plane is single-tenant and unique. It is on its own set of Amazon EC2 instances. run.

### 2.1 EKS control plane creation

Users can easily complete the creation of EKS clusters and working nodes through an eksctl command, but in order to let users better understand the working mode of EKS and better customize the configuration and resources required for ShinyProxy operation in independent steps, this article It will be divided into two stages to create separately. This part first completes the creation of the EKS cluster control plane. Refer to [eksctl: Creating a cluster](https://eksctl.io/usage/creating-and-managing-clusters/).

```
## Global environment configuration
## AWS regional settings, this environment setting can be added to the profile of the operating system user environment to achieve automatic setting after login
REGION_EKS=cn-northwest-1
export AWS_DEFAULT_REGION=$REGION_EKS

## EKS cluster name
EKS_CLUSTER_NAME=EKS-SHINY

## The tag information of the EKS cluster can be customized for subsequent expense tracking and other management (optional)
TAG="Environment=Alpha-Test,Application=Shiny"

## The following command will create an EKS cluster named EKS-SHINY, version 1.15 without any working node group
## The meaning of each parameter can be viewed through eksctl create cluster --help

eksctl create cluster \
  --name=$EKS_CLUSTER_NAME \
  --version=1.15 \
  --region=$REGION_EKS \
  --tags $TAG \
  --without-nodegroup \
  --asg-access \
  --full-ecr-access \
  --alb-ingress-access

## Cluster configuration usually takes 10 to 15 minutes, this process will automatically create the required VPC/security group/IAM role/EKS API service and many other resources

## Cluster access test, normally it will display the cluster's CLUSTER-IP and other information
kubectl get svc --watch

## To delete the created EKS cluster, use the following command
## eksctl delete cluster --name=$EKS_CLUSTER_NAME --region=$REGION_EKS
```
The management server terminal will display the creation process

![Terminal display EKS creation process](https://github.com/MMichael-S/ShinyProxyOnEKS-China/blob/master/img/EKS-Create.png)
Caption: The terminal displays the EKS creation process

eksctl will complete the EKS cluster creation through the AWS Cloudformation service. You can also view the creation process in the Cloudformation service in the console, and view and analyze the events in Cloudformation when an exception occurs to understand the detailed cause of the error.

![Cloudformation shows EKS creation process](https://github.com/MMichael-S/ShinyProxyOnEKS-China/blob/master/img/EKS-Create-Console.png)
Caption: Cloudformation shows EKS creation process

### 2.2 Node group creation

The worker thread computer in Kubernetes is called a “node”, and the Amazon EKS worker node is connected to the control plane of the cluster through the cluster API server endpoint. A node group is one or more Amazon EC2 instances deployed in an Amazon EC2 Auto Scaling Group. The EC2 instance will also be the environment in which ShinyProxy and Shiny applications are actually running. Each node group must use the same instance type, but an EKS cluster can contain multiple node groups, so you can choose to create multiple different node groups to support different node types according to the application scenario.

Below we will create the node group in EKS by using eksctl and [parameter file](https://eksctl.io/usage/schema/). Using the parameter file can facilitate later modification and multiplexing.

If you want to log in to the EKS working node through SSH in the future, you need to configure the ssh section and the parameter publicKeyName in it. You can use the same key pair as the management machine EC2 created previously, or you can create a new key pair and assign it to the EKS node. .

```
mkdir -p ~/download
cd ~/download

## Related parameters can be referred to: https://eksctl.io/usage/schema/
## The following command will create a node group named EKS-Shiny-NodeGroup with 2 m5.xlarge type EC2 nodes and a storage space of 30GB
## Some parameters can be modified according to actual needs, such as EC2 instance type, number, EBS volume size, etc.
## In the parameter file, you can add node labels (labels), scripts that are automatically executed at startup, and additional policies
## When adding a Policy, you must include the default AmazonEKSWorkerNodePolicy and AmazonEKS_CNI_Policy

## Node group name
NODE_GROUP_NAME="EKS-Shiny-NodeGroup"

## Edit NodeGroup configuration file, the file name can be customized
vi EKS-Shiny-NodeGroup.yaml

apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: EKS-SHINY
  region: cn-northwest-1

nodeGroups:
  -name: EKS-Shiny-NodeGroup
    instanceType: m5.xlarge
    minSize: 1
    maxSize: 10
    desiredCapacity: 2
    volumeSize: 30
    ssh:
      allow: true
      publicKeyName: # EC2 key pair
    labels: {role: worker, NodeSize: m5.xlarge}
    tags:
      {
      "Environment": "Alpha-Test",
      "Application": "ShinyProxy"
      }
    iam:
      attachPolicyARNs:
        -arn:aws-cn:iam::aws:policy/AmazonEKSWorkerNodePolicy
        -arn:aws-cn:iam::aws:policy/AmazonEKS_CNI_Policy
        -arn:aws-cn:iam::aws:policy/AmazonS3FullAccess
      withAddonPolicies:
        albIngress: true
        autoScaler: true
        cloudWatch: true
        ebs: true
        efs: true
```

## Create NodeGroup
`eksctl create nodegroup --config-file=./EKS-Shiny-NodeGroup.yaml`

## In some abnormal cases, if you need to delete the NodeGroup that failed before, you can execute the following command
## eksctl delete nodegroup --config-file=./EKS-Shiny-NodeGroup.yaml --approve

## View the current node group information and confirm that the status of each node is displayed as "Ready"
`kubectl get node --wide --watch`


## License

This library is licensed under the MIT-0 License. See the LICENSE file.