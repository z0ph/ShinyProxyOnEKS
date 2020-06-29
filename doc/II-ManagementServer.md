## II. Management Machine Configuration

In order to better complete the creation and configuration of the EKS cluster and related services in the next steps, to avoid problems caused by factors such as abnormal local environments or network abnormalities, it is recommended to be able to configure an EC2 server as a management server. Used as a bastion machine to provide more secure access to AWS services. In the deployment link involved in this article, use a t3.small (2vCPU/2GB memory) configuration type EC2. If EC2 is already available in the AWS region where the EKS cluster is to be created, this step can be ignored. We will proceed with the necessary user creation, EC2 creation, and environment setup and software deployment in EC2.

### Create an IAM user

You need to have IAM users who have been assigned appropriate permissions to use AWS and complete the subsequent configuration process. If this step has not been performed, your AWS account administrator can refer to
Create this link: [Create your first IAM administrator user and group](https://docs.aws.amazon.com/zh_cn/IAM/latest/UserGuide/getting-started_create-admin-group.html) , Please keep your IAM [user password](https://docs.aws.amazon.com/zh_cn/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) and [access key information](https://docs.aws.amazon.com/zh_cn/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey).

### Start the EC2 management machine

Use your IAM user to complete EC2 creation. EC2 Linux instance startup and connection can refer to: [Amazon EC2 Linux Instance Getting Started](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/EC2_GetStarted.html )
This article uses the Ubuntu 16.04 operating system image frequently used by users in the Ningxia region as an example to complete the subsequent configuration. The AMI ID is ami-09081e8e3d61f4b9e. You can view the details of this AMI through the AWS console.
[Image: image.png] During the EC2 startup process, you will be prompted to create a subsequent [EC2 key pair for connection](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/ec2-key-pairs.html), please keep it properly and pay attention to the file safety.

After the startup is complete, you can apply for EC2 binding [elastic IP address](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html) (Elastic IP) An unchanging public IP address has been obtained for future visits.


### Create an IAM role to attach to the management machine

In order to enable the management machine to access AWS services and have corresponding operation permissions, you need to create [IAM role for EC2](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html), and attach this IAM role to the instance. In order to simplify the permission setting and successfully complete the subsequent steps, the IAM role can be assigned an administrator access policy (*AdministratorAccess Policy*) during the testing phase. But in the production environment, stricter permission control is required, see [IAM Best Practices](https://docs.aws.amazon.com/zh_cn/IAM/latest/UserGuide/best-practices.html), For IAM permissions related to EKS services, see [IAM for Amazon EKS](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/security-iam.html).

After that, we can connect to the management machine through SSH to complete the subsequent management machine software deployment.

* Attach IAM roles to instances

### Management machine configuration: AWSCLI

[AWS CLI](https://docs.aws.amazon.com/zh_cn/cli/latest/userguide/cli-chap-welcome.html) is a unified command line interface tool for managing AWS services, this step can refer to : [Install the AWS CLI version on Linux](https://docs.aws.amazon.com/zh_cn/cli/latest/userguide/install-linux.html).
**Note: The AWS CLI command-line tool is pre-installed in some AMI images, and the version of the AWS CLI is 1.16.308 or later, this step can be ignored. **

```
## Ubuntu system update
sudo apt update -y
sudo apt upgrade -y

## If you are prompted to restart after the update, please complete the restart
sudo reboot

## Confirm Python version is 2.7.9 or higher
python3 --version

## Install pip and awscli
sudo apt install python3-pip -y
`pip3 install awscli ``--``upgrade ``--``user`

`## View awscli version`
`aws ``--``version`

`## Test the AWS CLI configuration, ``In normal circumstances, it will display the bucket information under the current account or empty information without error`
## If abnormal, please check whether IAM Role has been successfully bound to EC2
`REGION_EKS``=``cn``-``northwest``-``1`
`export`` AWS_DEFAULT_REGION``=``$REGION_EKS`
`aws s3 ls`
```

### Management machine configuration: Docker

The Docker environment in the EC2 management machine will allow us to test the Shiny container and use it in the push process of the Docker container to the ECR mirror warehouse in the subsequent steps.
**Note: Docker is pre-installed in some AWS images, but it is still recommended to refer to [Installation of New Docker Version](https://docs.docker.com/install/linux/docker-ce/ubuntu/) to complete the container environment Deployment.**


```
## Docker installation
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add-
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

## View the current valid version of Docker CE
sudo apt-cache madison docker-ce

## Simple Docker test, it will normally display "Hello from Docker!"
sudo docker run hello-world

## Authorize the current user to have Docker operation permissions, and the permissions will take effect after logging out and logging in again
sudo usermod -aG docker $USER

## View Docker information, you can follow the version information, such as "Server Version: 19.03.8"
docker info

```

### Management machine configuration: eksctl

[eksctl](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/eksctl.html) is provided by [Weave works](https://www.weave.works/) for A simple command-line utility for creating and managing Kubernetes clusters on Amazon EKS. Compared to creating and managing EKS clusters through a console interface or template, it provides a more convenient and simple way. For more information, refer to: [ eksctl-The official CLI for Amazon EKS] (https://eksctl.io/).

**To cooperate with the successful implementation of Amazon EKS services in Ningxia and Beijing, the official version of eksctl 0.15.0 has supported EKS services in Ningxia and Beijing.**


```
## Create a directory named download under the root directory of the current user. This directory will be used for subsequent file downloads and other purposes, and can be changed to other directory names as needed
mkdir -p ~/download
cd ~/download

## Download the latest stable version of eksctl latest: https://github.com/weaveworks/eksctl/releases
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/eksctl

## View the current version
eksctl version

```

### Management machine configuration: kubectl

[Kubectl](https://kubernetes.io/zh/docs/reference/kubectl/overview/) is a command-line interface for running instructions to the Kubernetes cluster, which will be used for management and monitoring after the EKS cluster is created And deployment of applications and services. The deployment process can be referred to: [install kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html).


```
cd ~/download

## With the upgrade of the EKS cluster version, the kubectl version provided by AWS may change in the future. Please read the installation reference document for the latest download link and installation method before downloading
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/linux/amd64/kubectl

chmod +x ./kubectl

cp ./kubectl $HOME/.local/bin/kubectl

echo'export PATH=$PATH:$HOME/bin' >> ~/.bashrc

kubectl version --short --client

```

## License

This library is licensed under the MIT-0 License. See the LICENSE file.