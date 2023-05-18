terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.1.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  shared_config_files      = ["./.aws_credentials/config"]
  shared_credentials_files = ["./.aws_credentials/credentials"]
  profile                  = "angelo"
}

provider "ansible" {
  # Configuration options
}

# Create a VPC
resource "aws_vpc" "sandbox" {
  cidr_block = "10.25.0.0/16"
  tags = {
    Name = "sandbox"
  }
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.sandbox.id
  cidr_block = "10.25.1.0/24"

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.sandbox.id
  cidr_block = "10.25.2.0/24"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_internet_gateway" "sandbox_igw" {
  vpc_id = aws_vpc.sandbox.id

  tags = {
    Name = "My Internet Gateway"
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
    Name = "public_rt"
  }
}

/*
resource "aws_route_table" "private1" {
  # The VPC ID.
  vpc_id = aws_vpc.main.id

  route {
    # The CIDR block of the route.
    cidr_block = "0.0.0.0/0"

    # Identifier of a VPC NAT gateway.
    nat_gateway_id = aws_nat_gateway.gw1.id
  }

  # A map of tags to assign to the resource.
  tags = {
    Name = "private1"
  }
}*/

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
  key_name   = "myKey" # Create a "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ${path.cwd}/.ssh/myKey.pem"
  }

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "chmod 600 ${path.cwd}/.ssh/myKey.pem"
  }
}

resource "aws_security_group" "main" {
  name        = "allow_ssh"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.sandbox.id

  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
}

variable "instance_controlplane_count" {
  default = 1
}

variable "instance_worker_count" {
  default = 2
}

variable "instance_type" {
  default = "t3.micro"
}

variable "instance_ami" {
  default = "ami-0a6351192ce04d50c"
}

resource "aws_instance" "controlplane" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  count                       = var.instance_controlplane_count
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  tags = {
    Name = "kubemaster-${count.index + 1}"
  }

  key_name               = "myKey"
  vpc_security_group_ids = [aws_security_group.main.id]

  provisioner "remote-exec" {
    inline = [
      "touch hello.txt",
      "echo helloworld remote provisioner >> hello.txt",
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("${path.cwd}/.ssh/myKey.pem")
    timeout     = "4m"
    insecure    = false
  }
}

resource "aws_instance" "worker" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  count                       = var.instance_worker_count
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  tags = {
    Name = "kubenode-${count.index + 1}"
  }
  key_name               = "myKey"
  vpc_security_group_ids = [aws_security_group.main.id]
}

# Ansible Section

resource "ansible_host" "kubemaster" {
  name   = aws_instance.controlplane[count.index].public_ip
  groups = ["controlplanes"]

  variables = {
    ansible_user                 = "ec2-user"
    ansible_ssh_private_key_file = "./.ssh/myKey.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = aws_instance.controlplane[count.index].tags["Name"]
    greetings                    = "from host!"
    some                         = "variable"
  }
  count = var.instance_controlplane_count
}

resource "ansible_host" "kubenode" {
  name   = aws_instance.worker[count.index].public_ip
  groups = ["workers"]

  variables = {
    ansible_user                 = "ec2-user"
    ansible_ssh_private_key_file = "./.ssh/myKey.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = aws_instance.worker[count.index].tags["Name"]
    greetings                    = "from host!"
    some                         = "variable"
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