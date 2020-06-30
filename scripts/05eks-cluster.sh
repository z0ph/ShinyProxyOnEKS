#!/bin/bash

## EKS cluster name
EKS_CLUSTER_NAME=EKS-ZHY
## AWS Region
REGION_EKS=eu-west-1
## Can customize Tag information for subsequent cost tracking and other management (optional)
TAG="Environment=dev,Application=ShinyProxy"
## For configuration file method, please refer to:
## https://github.com/weaveworks/eksctl/blob/master/examples/02-custom-vpc-cidr-no-nodes.yaml

eksctl create cluster \
  --name=$EKS_CLUSTER_NAME \
  --region=$REGION_EKS \
  --tags $TAG \
  --without-nodegroup \
  --asg-access \
  --full-ecr-access \
  --appmesh-access \
  --alb-ingress-access

## Description of additional options, adding the following options will automatically create related IAM strategies during EKS cluster creation
<<COMMENT
Cluster and nodegroup add-ons flags:
      --asg-access            enable IAM policy for cluster-autoscaler
      --external-dns-access   enable IAM policy for external-dns
      --full-ecr-access       enable full access to ECR
      --appmesh-access        enable full access to AppMesh
      --alb-ingress-access    enable full access for alb-ingress-controller
COMMENT

## To delete the created EKS cluster, use the following command
## eksctl delete cluster --name=$EKS_CLUSTER_NAME --region=$REGION_EKS

## Cluster configuration usually takes 10 to 15 minutes
## The cluster will automatically create the required VPC/security group/IAM role/EKS API service and other resources

## Cluster access test
## watch -n 2 kubectl get svc
kubectl get svc

## NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
## kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   11m


