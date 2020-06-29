## Build a complete operation, maintenance and monitoring system

### Commonly used EKS monitoring instructions

```
## View cluster information
Amazon EKS describe-cluster --name $EKS_CLUSTER_NAME --region=$REGION_EKS

## View NodeGroup information
eksctl get nodegroups --cluster $EKS_CLUSTER_NAME --region $REGION_EKS

## View node status
kubectl get nodes -o wide

## View system pod status
kubectl -n kube-system get pods -o wide

## View user Pods status
kubectl get pods -o wide

## View the current Shinyproxy Pod information, such as the current version of the container
kubectl describe pods/shinyproxy-xxxxxxxxxxxxxxx-xxxxx

## View Shinyproxy's running logs, if you want to know the running status and failure analysis
kubectl logs -f -c shinyproxy shinyproxy-xxxxxxxxx-xxxxxxx
```

### Enable Cloudwatch monitoring for EKS cluster

Cloudwatch monitoring can be enabled for EKS clusters. When a fault or abnormality occurs, it is easy to analyze and handle the abnormality that occurred, and it is also convenient to send monitoring logs and information to the AWS service support team for more in-depth analysis. Reference: [Amazon EKS Control Level Logging](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/control-plane-logs.html)

```
## We can complete the monitoring function of the EKS cluster through the console or the following command
eksctl utils update-cluster-logging --enable-types all --approve --region=cn-northwest-1 --cluster=EKS cluster name
```

### Configure the graphical management panel for the EKS cluster

The EKS cluster can be configured with a graphical management panel that is easier to view and manage the operating status of the cluster, nodes, pods, etc. After the configuration, users can easily view the operation status, resource consumption, and abnormalities of the cluster at different levels in the panel And fault information. You can refer to the tutorial: [Deploy Kubernetes Web UI (Control Panel)](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/dashboard-tutorial.html) to complete the corresponding configuration.


## License

This library is licensed under the MIT-0 License. See the LICENSE file.