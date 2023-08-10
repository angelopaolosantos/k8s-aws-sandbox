# k8s-aws-sandbox

Requirements:
add argument cloud-provider: "external" to apiServer and controllerManager
add "kubernetes.io/cluster/kubernetes" = "owned" tags to:
- nodes
- subnets
- security groups
attach aws required control-plane role/policy
attach aws required node role/policy

Add arguments to aws cloud-controller-manager daemon-set:
--cluster-cidr=10.244.0.0/16  
--allocate-node-cidrs=true    
--configure-cloud-routes=false

Installs the aws cloud-controller-manager.

helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
helm repo update

# Helm 3
$ helm upgrade --install aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager

# Helm 3
$ helm uninstall [RELEASE_NAME]

# Helm 3 or 2
$ helm upgrade [RELEASE_NAME] cloud-provider-aws/charts/aws-cloud-controller-manager  [flags]

reference:
https://github.com/kubernetes/cloud-provider-aws/tree/master/charts/aws-cloud-controller-manager

Join nodes to cluster
kubeadm join --config <config file>