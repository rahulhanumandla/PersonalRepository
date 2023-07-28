terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  #profile = "default"
}


resource "aws_key_pair" "rahulkeynew" {
  key_name   = "rahulkeynew"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "rahulkeynew1" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "rahulkeynew"
}

#storing statefile in S3 bucket
terraform {
  backend "s3" {
    bucket = "hanumandlarahulbucket1"
    key    = "VPC/terraform.state"
    region = "us-east-1"
    #profile = "default"
  }
}

# VPC
resource "aws_vpc" "VPCTF1" {
  cidr_block           = var.cidr
  instance_tenancy     = "default"
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name      = "Terraform VPC"
    CreatedBy = "iac - terraform"
  }
}

# Subnet - Public -1 
resource "aws_subnet" "TerraformVPC_public_subnet_1" {
  vpc_id                  = aws_vpc.VPCTF1.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name      = "TerraformVPC_public_subnet_1"
    CreatedBy = "iac - terraform"
  }
}

# Subnet - Public -2 
resource "aws_subnet" "TerraformVPC_public_subnet_2" {
  vpc_id                  = aws_vpc.VPCTF1.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name      = "TerraformVPC_public_subnet_2"
    CreatedBy = "iac - terraform"
  }
}

# Subnet - Private - 1 
resource "aws_subnet" "TerraformVPC_private_subnet_1" {
  vpc_id            = aws_vpc.VPCTF1.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name      = "TerraformVPC_private_subnet_1"
    CreatedBy = "iac - terraform"
  }
}

# Subnet - Private - 2 
resource "aws_subnet" "TerraformVPC_private_subnet_2" {
  vpc_id            = aws_vpc.VPCTF1.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name      = "TerraformVPC_private_subnet_2"
    CreatedBy = "iac - terraform"
  }
}

# RTB - Public-1
resource "aws_route_table" "TerraformVPC_public_rtb" {
  vpc_id = aws_vpc.VPCTF1.id

  tags = {
    Name      = "TerraformVPC_public_rtb"
    CreatedBy = "iac - terraform"
  }
}

# RTB - Private-1
resource "aws_route_table" "TerraformVPC_private_rtb" {
  vpc_id = aws_vpc.VPCTF1.id

  tags = {
    Name      = "TerraformVPC_private_rtb"
    CreatedBy = "iac - terraform"
  }
}

# Subnet Association with Public Route Table 
resource "aws_route_table_association" "TerraformVPC_public_subnet_1_association" {
  subnet_id      = aws_subnet.TerraformVPC_public_subnet_1.id
  route_table_id = aws_route_table.TerraformVPC_public_rtb.id
}

# Subnet Association with Public Route Table 
resource "aws_route_table_association" "TerraformVPC_public_subnet_2_association" {
  subnet_id      = aws_subnet.TerraformVPC_public_subnet_2.id
  route_table_id = aws_route_table.TerraformVPC_public_rtb.id
}

# Subnet Association with Private Route Table
resource "aws_route_table_association" "TerraformVPC_private_subnet_1_association" {
  subnet_id      = aws_subnet.TerraformVPC_private_subnet_1.id
  route_table_id = aws_route_table.TerraformVPC_private_rtb.id
}

# Subnet Association with Private Route Table
resource "aws_route_table_association" "TerraformVPC_private_subnet_2_association" {
  subnet_id      = aws_subnet.TerraformVPC_private_subnet_2.id
  route_table_id = aws_route_table.TerraformVPC_private_rtb.id
}

# IGW 
resource "aws_internet_gateway" "TerraformVPC_igw" {
  vpc_id = aws_vpc.VPCTF1.id

  tags = {
    Name      = "TerraformVPC_igw"
    CreatedBy = "iac - terraform"
  }

}

# EIP 
resource "aws_eip" "TerraformVPC_eip" {
  vpc = true
}

# NAT Gateway & Attach EIP to NAT GATEWAY
resource "aws_nat_gateway" "TerraformVPC_natgw" {
  allocation_id = aws_eip.TerraformVPC_eip.id
  subnet_id     = aws_subnet.TerraformVPC_public_subnet_1.id

  tags = {
    Name      = "TerraformVPC_natgw"
    CreatedBy = "iac - terraform"
  }
}

# Create Routing to Public-RTB From INTGW
resource "aws_route" "TerraformVPC_rtb_igw" {
  route_table_id         = aws_route_table.TerraformVPC_public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.TerraformVPC_igw.id

}

# Create Routing to Private-RTB From NATGW
resource "aws_route" "TerraformVPC_allow_natgw" {
  route_table_id         = aws_route_table.TerraformVPC_private_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.TerraformVPC_natgw.id

}

# NACL 
resource "aws_network_acl" "TerraformVPC_nacl" {
  vpc_id     = aws_vpc.VPCTF1.id
  subnet_ids = [aws_subnet.TerraformVPC_public_subnet_1.id, aws_subnet.TerraformVPC_public_subnet_2.id, aws_subnet.TerraformVPC_private_subnet_1.id, aws_subnet.TerraformVPC_private_subnet_2.id]

  # ingress / inbound
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  # egress / outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name      = "TerraformVPC_nacl"
    CreatedBy = "IAC - Terraform"
  }

}

# SG For Bastion
resource "aws_security_group" "TerraformVPC_sg_bastion" {
  vpc_id      = aws_vpc.VPCTF1.id
  name        = "sg_bastion"
  description = "Allow SSH And RDP"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "TerraformVPC_sg_bastion"
    Description = "Allow SSH and RDP"
    CreatedBy   = "IAC - Terraform"
  }

}

# SG For WebServer
resource "aws_security_group" "TerraformVPC_sg_web" {
  vpc_id      = aws_vpc.VPCTF1.id
  name        = "sg_web"
  description = "Allow SSH - RDP - HTTP - DB "

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "TerraformVPC_sg_web"
    Description = "Allow SSH - RDP - HTTP - DB - TOMCAT"
    CreatedBy   = "IAC - Terraform"
  }

}

#Create EC2 instance in Public for Bastion (Windows)

resource "aws_instance" "cloudbinary_bastion" {
  ami                    = "ami-0fc682b2a42e57ca2"
  instance_type          = "t2.micro"
  key_name               = "rahulkeynew"
  subnet_id              = aws_subnet.TerraformVPC_public_subnet_1.id
  vpc_security_group_ids = ["${aws_security_group.TerraformVPC_sg_bastion.id}"]

  tags = {
    Name      = "TerraformVPC_bastion"
    CreatedBy = "IAC - Terraform"
    OSType    = "Windows"
  }
}

# EC2 Instance in Private Subnet 
resource "aws_instance" "TerraformVPC_ubuntu_web" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.micro"
  key_name               = "rahulkeynew"
  subnet_id              = aws_subnet.TerraformVPC_private_subnet_1.id
  vpc_security_group_ids = ["${aws_security_group.TerraformVPC_sg_web.id}"]

  tags = {
    Name      = "Terraform_web"
    CreatedBy = "IAC - Terraform"
    OSType    = "Linux - Ubuntu 20.04"
  }
}


