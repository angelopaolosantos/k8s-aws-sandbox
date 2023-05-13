terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  shared_config_files      = ["./.aws_credentials/config"]
  shared_credentials_files = ["./.aws_credentials/credentials"]
  profile                  = "angelo"
}

# Create a VPC
resource "aws_vpc" "sandbox" {
  cidr_block = "10.25.0.0/16"
  tags = {
    Name = "sandbox"
  }
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
  key_name   = "myKey"       # Create a "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    //command = "echo '${tls_private_key.pk.private_key_pem}' > ./.ssh/myKey.pem"
    inline = [
      "echo '${tls_private_key.pk.private_key_pem}' > ./.ssh/myKey.pem",
      "chmod 600 ./.ssh/myKey.pem",
    ]
  }
}


resource "aws_instance" "controlplane" {
  depends_on = [ aws_key_pair.kp, tls_private_key.pk ]
  ami           = "ami-0a6351192ce04d50c"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"

  key_name= "myKey"
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
      user        = "ubuntu"
      private_key = file("${path.cwd}/.ssh/myKey.pem")
      timeout     = "4m"
   }

  tags = {
    Name = "controlplane"
  }
}

resource "aws_security_group" "main" {
  name        = "allow_ssh"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.sandbox.id

  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
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
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
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

/*
resource "aws_key_pair" "deployer" {
  key_name   = "aws_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbvRN/gvQBhFe+dE8p3Q865T/xTKgjqTjj56p1IIKbq8SDyOybE8ia0rMPcBLAKds+wjePIYpTtRxT9UsUbZJTgF+SGSG2dC6+ohCQpi6F3xM7ryL9fy3BNCT5aPrwbR862jcOIfv7R1xVfH8OS0WZa8DpVy5kTeutsuH5suehdngba4KhYLTzIdhM7UKJvNoUMRBaxAqIAThqH9Vt/iR1WpXgazoPw6dyPssa7ye6tUPRipmPTZukfpxcPlsqytXWlXm7R89xAY9OXkdPPVsrQdkdfhnY8aFb9XaZP8cm7EOVRdxMsA1DyWMVZOTjhBwCHfEIGoePAS3jFMqQjGWQd rahul@rahul-HP-ZBook-15-G2"
}*/

resource "aws_instance" "node1" {
  ami           = "ami-0a6351192ce04d50c"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  tags = {
    Name = "node1"
  }
}

resource "aws_instance" "node2" {
  ami           = "ami-0a6351192ce04d50c"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  tags = {
    Name = "node2"
  }
}

