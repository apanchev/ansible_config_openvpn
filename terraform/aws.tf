terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.12.1"
    }
  }
}

variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "SSH_KEY" {}
variable "SSH_IP" {}

provider "aws" {
  region = "us-west-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.SSH_KEY
}

resource "aws_vpc" "openvpn_vpc" {
  cidr_block = "10.42.0.0/16"
	enable_dns_hostnames = true
	tags = {
		name = "openvpn"
	}
}

resource "aws_internet_gateway" "openvpn_gateway" {
  vpc_id = aws_vpc.openvpn_vpc.id

  tags = {
    Name = "openvpn"
  }
}

resource "aws_default_route_table" "openvpn_route" {
	default_route_table_id = aws_vpc.openvpn_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.openvpn_gateway.id
  }
}

resource "aws_default_security_group" "openvpn_secu" {
  vpc_id      = aws_vpc.openvpn_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.SSH_IP]
  }
  ingress {
    description      = "OpenVPN port"
    from_port        = 1194
    to_port          = 1194
    protocol         = "udp"
    cidr_blocks      = [var.SSH_IP]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_subnet" "openvpn_subnet" {
  vpc_id            = aws_vpc.openvpn_vpc.id
  cidr_block        = "10.42.0.0/24"
  availability_zone = "us-west-1a"
	map_public_ip_on_launch = true
}

resource "aws_network_interface" "openvpn_interface" {
  subnet_id = aws_subnet.openvpn_subnet.id
}

resource "aws_instance" "openvpn_instance" {
  ami           = "ami-0a5cf2276636ccbe7"
  instance_type = "t2.nano"
	key_name      = aws_key_pair.deployer.key_name

	network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.openvpn_interface.id
  }
  tags = {
    Name = "openvpn"
  }
}

output "instance_public_ips" {
  value = aws_instance.openvpn_instance.*.public_ip
}
resource "local_file" "public_ips" {
  content  = "[all]\n${aws_instance.openvpn_instance.public_ip}"
  filename = "../ansible/ansible_hosts"
}