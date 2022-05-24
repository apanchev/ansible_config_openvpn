variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_ami" {
  type    = string
  default = "ami-0428a96ea4310aeb1"
}

variable "admin_ip" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.nano"
}

variable "ssh_key_name" {
  type    = string
  default = "apanchev"
}