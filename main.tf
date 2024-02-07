resource "aws_security_group" "kube-mutual-sg" {
  name   = "kube-mutual-sec-group"
  vpc_id = aws_vpc.sandbox.id
  tags = {
    Name = "kube-mutual-secgroup"
  }
}

resource "aws_security_group" "kube-worker-sg" {
  name   = "kube-worker-sec-group"
  vpc_id = aws_vpc.sandbox.id

  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "SSH Access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "NodePort Services"
      from_port        = 30000
      to_port          = 32767
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "Kubelet API"
      from_port        = 10250
      to_port          = 10250
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "Weave Net"
      from_port        = 6783
      to_port          = 6783
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "Weave Net"
      from_port        = 6783
      to_port          = 6784
      protocol         = "udp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    }

  ]
  tags = {
    Name                               = "kube-worker-secgroup"
    terraform_group                    = "k8s-aws-sandbox"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}

resource "aws_security_group" "kube-master-sg" {
  name   = "kube-master-sec-group"
  vpc_id = aws_vpc.sandbox.id

  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "SSH Access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "Kubernetes API server"
      from_port        = 6443
      to_port          = 6443
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "Kubelet API"
      from_port        = 10250
      to_port          = 10250
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "kube-scheduler"
      from_port        = 10259
      to_port          = 10259
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "kube-controller-manager"
      from_port        = 10257
      to_port          = 10257
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "etcd server client API"
      from_port        = 2379
      to_port          = 2380
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "Weave Net"
      from_port        = 6783
      to_port          = 6783
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    },
    {
      security_groups  = [aws_security_group.kube-mutual-sg.id]
      description      = "Weave Net"
      from_port        = 6783
      to_port          = 6784
      protocol         = "udp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
      cidr_blocks      = []
    }
  ]
  tags = {
    Name                               = "kube-master-secgroup"
    terraform_group                    = "k8s-aws-sandbox"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}

# Create a VPC
resource "aws_vpc" "sandbox" {
  cidr_block           = "10.25.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name            = "sandbox"
    terraform_group = "k8s-aws-sandbox"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.sandbox.id
  cidr_block = "10.25.1.0/24"

  tags = {
    Name                               = "public_subnet"
    terraform_group                    = "k8s-aws-sandbox"
    "kubernetes.io/cluster/kubernetes" = "owned"
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.sandbox.id
  cidr_block = "10.25.2.0/24"

  tags = {
    Name                               = "private_subnet"
    terraform_group                    = "k8s-aws-sandbox"
    "kubernetes.io/cluster/kubernetes" = "owned"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_internet_gateway" "sandbox_igw" {
  vpc_id = aws_vpc.sandbox.id

  tags = {
    Name            = "My Internet Gateway"
    terraform_group = "k8s-aws-sandbox"
  }
}

resource "aws_route_table" "public_rt" {
  # The VPC ID.
  vpc_id = aws_vpc.sandbox.id

  route {
    # The CIDR block of the route.
    cidr_block = "0.0.0.0/0"

    # Identifier of a VPC internet gateway or a virtual private gateway.
    gateway_id = aws_internet_gateway.sandbox_igw.id
  }

  # A map of tags to assign to the resource.
  tags = {
    Name            = "public_rt"
    terraform_group = "k8s-aws-sandbox"
  }
}

resource "aws_route_table_association" "public1" {
  # The subnet ID to create an association.
  subnet_id = aws_subnet.public_subnet.id

  # The ID of the routing table to associate with.
  route_table_id = aws_route_table.public_rt.id
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "myKey" # Create a "myKey" on AWS.
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Copy a "myKey.pem" to local computer.
    command = "echo '${tls_private_key.pk.private_key_pem}' > ${path.cwd}/.ssh/myKey.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/.ssh/myKey.pem"
  }

  tags = {
    terraform_group = "k8s-aws-sandbox"
  }
}


resource "aws_instance" "controlplane" {
  ami                  = var.instance_ami
  instance_type        = var.instance_controlplane_type
  iam_instance_profile = aws_iam_instance_profile.controlplane_profile.name
  count                = var.instance_controlplane_count
  subnet_id            = aws_subnet.public_subnet.id

  associate_public_ip_address = "true"
  tags = {
    Name                               = "kubemaster-${count.index + 1}"
    terraform_group                    = "k8s-aws-sandbox"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }

  key_name               = "myKey"
  vpc_security_group_ids = [aws_security_group.kube-mutual-sg.id, aws_security_group.kube-master-sg.id]

  provisioner "remote-exec" {
    inline = [
      "touch hello.txt",
      "echo helloworld remote provisioner >> hello.txt",
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.instance_user
    private_key = file("${path.cwd}/.ssh/myKey.pem")
    timeout     = "4m"
    insecure    = false
  }
}

resource "aws_instance" "worker" {
  ami                         = var.instance_ami
  instance_type               = var.instance_worker_type
  iam_instance_profile        = aws_iam_instance_profile.worker_profile.name
  count                       = var.instance_worker_count
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  tags = {
    Name                               = "kubenode-${count.index + 1}"
    terraform_group                    = "k8s-aws-sandbox"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
  key_name               = "myKey"
  vpc_security_group_ids = [aws_security_group.kube-mutual-sg.id, aws_security_group.kube-worker-sg.id]
}

# AWS Cloud Controller Requirements - Roles and Policies
resource "aws_iam_policy" "controlplane_policy" {
  name        = "controlplane_policy"
  path        = "/"
  description = "Policy requirement for AWS Cloud Controller Manager"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeVpcs",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:AttachLoadBalancerToSubnets",
          "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateLoadBalancerPolicy",
          "elasticloadbalancing:CreateLoadBalancerListeners",
          "elasticloadbalancing:ConfigureHealthCheck",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancerListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DetachLoadBalancerFromSubnets",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancerPolicies",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
          "iam:CreateServiceLinkedRole",
          "kms:DescribeKey"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
  tags = {
    terraform_group                    = "k8s-aws-sandbox"
  }
}

resource "aws_iam_role" "controlplane_role" {
  name = "controlplane_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    terraform_group                    = "k8s-aws-sandbox"
  }
}

resource "aws_iam_role_policy_attachment" "controlplane_role_policy" {
  role       = aws_iam_role.controlplane_role.name
  policy_arn = aws_iam_policy.controlplane_policy.arn
}

resource "aws_iam_instance_profile" "controlplane_profile" {
  name = "controlplane_profile"
  role = aws_iam_role.controlplane_role.name
  tags = {
    terraform_group                    = "k8s-aws-sandbox"
  }
}


resource "aws_iam_policy" "worker_policy" {
  name        = "worker_policy"
  path        = "/"
  description = "Policy requirement for AWS Cloud Controller Manager"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage"
        ],
        "Resource" : "*"
      }
    ]
  })
  tags = {
    terraform_group                    = "k8s-aws-sandbox"
  }
}

resource "aws_iam_role" "worker_role" {
  name = "worker_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    terraform_group                    = "k8s-aws-sandbox"
  }
}

resource "aws_iam_role_policy_attachment" "worker_role_policy" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.worker_policy.arn
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "worker_profile"
  role = aws_iam_role.worker_role.name
  tags = {
    terraform_group                    = "k8s-aws-sandbox"
  }
}


# Ansible Section 

resource "ansible_host" "kubemaster" {
  name   = aws_instance.controlplane[count.index].public_ip
  groups = ["controlplanes"]

  variables = {
    ansible_user                 = var.instance_user
    ansible_ssh_private_key_file = "./.ssh/myKey.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = aws_instance.controlplane[count.index].tags["Name"]
    greetings                    = "from host!"
    some                         = "variable"
    private_ip                   = aws_instance.controlplane[count.index].private_ip
  }
  count = var.instance_controlplane_count
}

resource "ansible_host" "kubenode" {
  name   = aws_instance.worker[count.index].public_ip
  groups = ["workers"]

  variables = {
    ansible_user                 = var.instance_user
    ansible_ssh_private_key_file = "./.ssh/myKey.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = aws_instance.worker[count.index].tags["Name"]
    greetings                    = "from host!"
    some                         = "variable"
    private_ip                   = aws_instance.worker[count.index].private_ip
  }
  count = var.instance_worker_count
}

resource "ansible_group" "controlplanes" {
  name     = "controlplanes"
  children = ["kubemaster"]
  variables = {
    hello = "from group!"
  }
}

resource "ansible_group" "workers" {
  name     = "workers"
  children = ["kubenode"]
  variables = {
    hello = "from group!"
  }
}

# Export Terraform variable values to an Ansible var_file
resource "local_file" "tf_ansible_vars_file_new" {
  content = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    # Generated by Terraform mgmt configuration.

    tf_instance_ami: ${var.instance_ami}
    tf_aws_instance_controlplace_ip: ${aws_instance.controlplane[0].public_ip}
    DOC
  filename = "./ansible/tf_ansible_vars_file.yaml"
}
