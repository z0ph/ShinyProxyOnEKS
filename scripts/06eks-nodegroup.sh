#!/bin/bash

#mkdir -p ~/download
#cd ~/download

## EKS cluster name
EKS_CLUSTER_NAME=EKS-ZHY
## AWS Region
REGION_EKS=eu-west-1
## Node group name
NODE_GROUP_NAME="NG-UNMANAGED-M5-x"

## Create NodeGroup
eksctl create nodegroup --config-file=../NG-UNMANAGED-M5-x.yaml

## In case of abnormal creation, you need to delete the previously failed NodeGroup and re-create it
## eksctl delete nodegroup --config-file=./NG-UNMANAGED-M5-x.yaml --approve

## After the creation is complete, you can manually manage the scaling of the NodeGroup, such as adjusting the number of original nodes from 2 to 3.
## The automatic expansion function will be added in the future
## eksctl scale nodegroup  --cluster $EKS_CLUSTER_NAME --name $NODE_GROUP_NAME --nodes 3

## The output displays information similar to the following:
<<COMMENT
/*
[ℹ]  scaling nodegroup stack "eksctl-EKS-HKG-nodegroup-NG-UNMANAGED-M5-x" in cluster eksctl-EKS-HKG-cluster
[ℹ]  scaling nodegroup, desired capacity from "2" to 3
*/
COMMENT
