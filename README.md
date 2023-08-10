# k8s-aws-sandbox

## Requirements:
1. Add argument cloud-provider: "external" to apiServer, controllerManager and kubelet
2. Add "kubernetes.io/cluster/kubernetes" = "owned" tags to control nodes, worker nodes, subnets, security groups
3. Add "kubernetes.io/role/elb" = 1 to Public (Internet-facing) subnets
4. Add "kubernetes.io/role/internal-elb" = 1 to private subnets
5. attach aws required control-plane role/policy
6. attach aws required node role/policy

7. arguments to aws cloud-controller-manager daemon-set:
```
--cluster-cidr=10.244.0.0/16  
--allocate-node-cidrs=true    
--configure-cloud-routes=false
```
8. Add AWS credentials in .aws_credentials/

## Run Terraform
```
terraform init
terraform plan
terraform apply
```

## Run Ansible
```
ansible-playbook -i ./ansible/inventory.yaml ./ansible/playbook.yaml
```

If the cloud controller manager isn’t started with --configure-cloud-routes: "false", then the route tables also needed to be tagged like the subnets.

##Install the aws cloud-controller-manager with Helm.

```
helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
helm repo update
```

Helm 3
```
helm upgrade --install aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager
```

Helm 3
```
helm uninstall [RELEASE_NAME]
```

Helm 3
```
helm upgrade [RELEASE_NAME] cloud-provider-aws/charts/aws-cloud-controller-manager  [flags]
```

or download manifests and adjust values such as image version
```
helm template aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager --output-dir /home/user/aws_ccm
```

reference:
https://github.com/kubernetes/cloud-provider-aws/tree/master/charts/aws-cloud-controller-manager
https://kubernetes.io/docs/tasks/administer-cluster/running-cloud-controller/#cloud-controller-manager
https://blog.scottlowe.org/2021/10/12/using-the-external-aws-cloud-provider-for-kubernetes/