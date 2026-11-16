
# ============================================================
# TERRAFORM + ANSIBLE + NGINX PROJECT
# COMPLETE AWS INFRASTRUCTURE
# REGION: EU-NORTH-1 (STOCKHOLM)
# TOTAL EC2: 12
# ============================================================

# -------------------- TERRAFORM ------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -------------------- AWS PROVIDER --------------------------

provider "aws" {
  region = "eu-north-1"
}

# -------------------- VARIABLES -----------------------------

variable "admin_cidr" {
  description = "Your public IP address with /32 for SSH access"
  type        = string
}

# -------------------- VPC -----------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "DevOps-VPC"
  }
}

# -------------------- INTERNET GATEWAY ----------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "DevOps-IGW"
  }
}

# -------------------- PUBLIC SUBNET 1 -----------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "DevOps-Public-Subnet-1"
  }
}

# -------------------- PUBLIC SUBNET 2 -----------------------

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "DevOps-Public-Subnet-2"
  }
}

# -------------------- PUBLIC ROUTE TABLE -------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "DevOps-Public-RT"
  }
}

# -------------------- ROUTE ASSOCIATIONS -------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# -------------------- ALB SECURITY GROUP ------------------

resource "aws_security_group" "alb_sg" {
  name        = "DevOps-ALB-SG"
  description = "Public HTTP and HTTPS access for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps-ALB-SG"
  }
}

# -------------------- EC2 SECURITY GROUP ------------------

resource "aws_security_group" "ec2_sg" {
  name        = "DevOps-EC2-SG"
  description = "Security group for Web, App and Ansible EC2"
  vpc_id      = aws_vpc.main.id

  # SSH from administrator IP
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # HTTP from inside VPC
  ingress {
    description = "HTTP internal VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # HTTPS internal VPC
  ingress {
    description = "HTTPS internal VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps-EC2-SG"
  }
}

# -------------------- SSH KEY PAIR -------------------------

resource "aws_key_pair" "devops_key" {
  key_name   = "terraform-ansible-nginx"
  public_key = file(pathexpand("~/.ssh/terraform-ansible-nginx.pub"))
}

# -------------------- AMAZON LINUX 2023 AMI ----------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# -------------------- 5 WEB EC2 ----------------------------

resource "aws_instance" "web" {
  count                  = 5
  ami                    = "ami-03b7abd930e847268"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.devops_key.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "Web-${count.index + 1}"
    Role = "web"
  }
}

# -------------------- 5 APP EC2 ----------------------------

resource "aws_instance" "app" {
  count                  = 2
  ami                    = "ami-03b7abd930e847268"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.devops_key.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "App-${count.index + 1}"
    Role = "app"
  }
}

# -------------------- ANSIBLE MASTER -----------------------

resource "aws_instance" "ansible_master" {
  ami                    = "ami-03b7abd930e847268"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.devops_key.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "Ansible-Master"
    Role = "ansible-master"
  }
}

# -------------------- ANSIBLE SLAVE ------------------------

resource "aws_instance" "ansible_slave" {
  ami                    = "ami-03b7abd930e847268"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.devops_key.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "Ansible-Slave"
    Role = "ansible-slave"
  }
}

# -------------------- APPLICATION LOAD BALANCER -----------

resource "aws_lb" "web_alb" {
  name               = "devops-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "DevOps-Web-ALB"
  }
}

# -------------------- ALB TARGET GROUP --------------------

resource "aws_lb_target_group" "web_tg" {
  name     = "devops-web-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "DevOps-Web-TG"
  }
}

# -------------------- WEB SERVER REGISTRATION -------------

resource "aws_lb_target_group_attachment" "web_servers" {
  count            = 5
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# -------------------- ALB LISTENER ------------------------

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# -------------------- OUTPUTS -----------------------------

output "web_public_ips" {
  description = "Public IPs of 5 Web EC2 servers"
  value       = aws_instance.web[*].public_ip
}

output "app_public_ips" {
  description = "Public IPs of 5 App EC2 servers"
  value       = aws_instance.app[*].public_ip
}

output "ansible_master_public_ip" {
  description = "Ansible Master Public IP"
  value       = aws_instance.ansible_master.public_ip
}

output "ansible_slave_public_ip" {
  description = "Ansible Slave Public IP"
  value       = aws_instance.ansible_slave.public_ip
}

output "all_instance_ids" {
  description = "All 12 EC2 instance IDs"
  value = concat(
    aws_instance.web[*].id,
    aws_instance.app[*].id,
    [aws_instance.ansible_master.id],
    [aws_instance.ansible_slave.id]
  )
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = aws_lb.web_alb.dns_name
}
