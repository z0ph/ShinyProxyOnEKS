#!/bin/bash

## 通过Console查看当前可用的VPC ID，及VPC中公有子网 Subnet ID
## 以上信息将用于确定管理机启动所依赖的VPC和子网
## 设置相应的环境变量

REGION_EKS=eu-west-1
export AWS_DEFAULT_REGION=$REGION_EKS
VPC_ID=<VPC-ID>
PUBLIC_SUBNET_ID=<SUBNET-ID>

## 创建管理机安全组，安全组名称为sg_eks_bastion
EKS_BASTION_SG=sg_eks_bastion
EKS_BASTION_SG_ID=$(aws ec2 create-security-group --vpc-id $VPC_ID --group-name $EKS_BASTION_SG --description "Bastion for EKS"|jq -r '.GroupId')
echo $EKS_BASTION_SG_ID

## 创建安全组中针对SSH访问的22端口访问许可
aws ec2 authorize-security-group-ingress --group-id $EKS_BASTION_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 

## 如有其他端口开放要求，可参照以下例子添加
## 为了EC2安全，只开放确定需要开放的端口，切记开放所有端口
## aws ec2 authorize-security-group-ingress --group-id $EKS_BASTION_SG_ID --protocol tcp --port "8000-9999" --cidr 0.0.0.0/0

## 管理机配置
##    AMI：Ubuntu 16.04 AMI：ami-9f793dee
##    EC2实例类型：c5.large (2vCPU/4GB)
##    根卷 20GB
##    子网：公有子网

BASTION_INSTANCE_ID=$(aws ec2 run-instances --image-id ami-9f793dee \
    --security-group-ids $EKS_BASTION_SG_ID \
    --key-name $KEYPAIR_NAME \
    --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp2\"}}]" \
    --instance-type c5.large \
    --count 1 \
    --subnet-id $PUBLIC_SUBNET_ID \
    --associate-public-ip-address \
    --tag-specifications "ResourceType="instance",Tags=[{Key="Name",Value="EKS_BASTION"}]" \
    --region $REGION_EKS \
    | jq -r '.Instances[0].InstanceId')

## 申请弹性IP，并与EC2绑定
## 弹性IP可保证管理机实例在停止和重新启动后拥有不变的公网IP地址
export BASTION_EIP=$(aws ec2 allocate-address --region $REGION_EKS | jq -r '.PublicIp')
aws ec2 associate-address --instance-id $BASTION_INSTANCE_ID --public-ip $BASTION_EIP --region $REGION_EKS

