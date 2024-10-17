terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.72.1"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "dpw-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    name = "dpw-vpc"
  }
}
resource "aws_subnet" "dpw-public_subnet_01" {
    vpc_id = aws_vpc.dpw-vpc.id
    cidr_block = "10.1.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        name = "dpw-public_subnet_01"
    }
}
resource "aws_subnet" "dpw-public_subnet_02" {
    vpc_id = aws_vpc.dpw-vpc.id
    cidr_block = "10.1.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1b"
    tags = {
        name = "dpw-public_subnet_02"
    }
}

resource "aws_internet_gateway" "dpw-igw" {
  vpc_id = aws_vpc.dpw-vpc.id

  tags = {
    Name = "dpw-igw"
  }
}
resource "aws_route_table" "dpw-public-rt" {
  vpc_id = aws_vpc.dpw-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpw-igw.id
  }
  tags = {
    Name = "dpw-public-rt"
  }
}
resource "aws_route_table_association" "dpw-rta-public-subnet-01" {
  subnet_id      = aws_subnet.dpw-public_subnet_01.id
  route_table_id = aws_route_table.dpw-public-rt.id
}

resource "aws_route_table_association" "dpw-rta-public-subnet-02" {
  subnet_id      = aws_subnet.dpw-public_subnet_02.id
  route_table_id = aws_route_table.dpw-public-rt.id
}
resource "aws_instance" "server" {
    ami = "ami-0866a3c8686eaeeba"
    instance_type = "t2.micro"
    key_name = "Master_keypair"
    vpc_security_group_ids = [aws_security_group.ssh-sg.id]
    subnet_id = aws_subnet.dpw-public_subnet_01.id
    for_each = toset(["Jenkins-node" , "build-slave" , "Ansible"]) 
        tags = {
            name = "${each.key}"
        }
    }


resource "aws_security_group" "ssh-sg" {
    name = "ssh-sg"
    description = "allow ssh inbound"
    vpc_id = aws_vpc.dpw-vpc.id
        
      ingress {
        description = "ssh access"
        from_port   = 22
        to_port     = 22
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
        Name = "ssh-sg"
      }
    }    
    

