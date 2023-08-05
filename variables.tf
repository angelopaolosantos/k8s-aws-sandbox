variable "aws_user_profile" {
  default = "angelo" # Update to aws user profile name in credentials
}

variable "instance_controlplane_count" {
  default = 1
}

variable "instance_worker_count" {
  default = 2
}

variable "instance_type" {
  # default = "t3.micro"
  default = "t3.medium"
}

variable "instance_ami" {
  default = "ami-08766f81ab52792ce" # Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
}

variable "instance_user" {
  default = "ubuntu"
}
