# creating VPC

resource "aws_vpc" "vpc-tf" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "My vpc-tf"
  }
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Pub sub1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Pub sub2"
  }
}

resource "aws_db_subnet_group" "ex_sub_group" {
  name       = "ex_sub_group"
  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc-tf.id

  tags = {
    Name = "Int Gateway tf"
  }
}

resource "aws_route_table" "pb_route_table" {
  vpc_id = aws_vpc.vpc-tf.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route Table tf"
  }
}

resource "aws_route_table_association" "public_subnet_route_table_assoc1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.pb_route_table.id
}
resource "aws_route_table_association" "public_subnet_route_table_assoc2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.pb_route_table.id
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "myKeytf" # Create a "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh
}

resource "aws_security_group" "ssh" {
  name   = "SSH"
  vpc_id = aws_vpc.vpc-tf.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this for production environments
    security_groups = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH Security Group"
  }
}

resource "aws_instance" "webserver" {
  ami                         = "ami-0de8a7e805b017a1f" # Replace with your desired AMI
  instance_type               = "t2.micro"              # Replace with your desired instance type
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  subnet_id                   = aws_subnet.public1.id
  associate_public_ip_address = true
  key_name                    = "myKeytf"
  tags = {
    Name = "Web Server"
  }
}




resource "aws_db_instance" "RDSterra" {
  identifier                   = "db1"
  instance_class               = "db.t3.micro"
  engine_version               = "8.0.35"
  engine                       = "mysql"
  multi_az                     = false
  username                     = "yashkr123"
  password                     = "yashkr123"
  storage_type                 = "gp2"
  allocated_storage            = 20
  vpc_security_group_ids       = [aws_security_group.ssh.id]
  db_subnet_group_name         = aws_db_subnet_group.ex_sub_group.name
  publicly_accessible          = true
  performance_insights_enabled = false
  port                         = 3306

  tags = {
    Name = "db1"
    Env  = "Dev/Test"

  }
}

output "public_ip" {
  value = aws_instance.webserver.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.RDSterra.endpoint
}
