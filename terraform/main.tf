terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.15.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "openvpn_vpc" {
  cidr_block           = "10.42.0.0/16"
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

resource "aws_security_group" "default" {
  name   = "openvpn"
  vpc_id = aws_vpc.openvpn_vpc.id
}

resource "aws_security_group_rule" "ingress_open_ssh" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.admin_ip]
}
resource "aws_security_group_rule" "ingress_open_vpn" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "tcp"
  cidr_blocks       = [var.admin_ip]
}
resource "aws_security_group_rule" "egress_open_all" {
  security_group_id = aws_security_group.default.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_subnet" "openvpn_subnet" {
  vpc_id                  = aws_vpc.openvpn_vpc.id
  cidr_block              = "10.42.0.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_network_interface" "openvpn_interface" {
  subnet_id = aws_subnet.openvpn_subnet.id
}

data "aws_key_pair" "default" {
  key_name = var.ssh_key_name
}

resource "aws_instance" "openvpn_instance" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.default.key_name

  user_data = templatefile("user_data.sh", {})

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.openvpn_interface.id
  }
  tags = {
    name = "openvpn"
  }
}

output "instance_public_ips" {
  value = aws_instance.openvpn_instance.*.public_ip
}
resource "local_file" "public_ips" {
  content  = "[all]\n${aws_instance.openvpn_instance.public_ip}"
  filename = "../ansible/ansible_hosts"
}