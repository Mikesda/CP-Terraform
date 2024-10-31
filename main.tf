provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

# Criar a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Criar uma sub-rede pública em us-west-2a
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/27"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
}

# Criar uma sub-rede privada em us-west-2b para o RDS
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/27"
  availability_zone = "us-west-2b"
}

# Criar uma segunda sub-rede privada em us-west-2c para o RDS
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/27"
  availability_zone = "us-west-2c"
}

# Gateway de internet para permitir o acesso público das instâncias EC2
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Rota pública para a sub-rede pública
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Grupo de segurança para as instâncias EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
}

# Grupo de segurança para o RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instância do RDS PostgreSQL na sub-rede privada
resource "aws_db_instance" "my_rds" {
  engine               = "postgres"
  identifier           = "myrdsinstance"
  allocated_storage    = 20
  instance_class       = "db.t3.micro"
  username             = "usradmin"
  password             = "S3nhaSup34S3gura"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet.id
  skip_final_snapshot  = true
}

# Definir sub-rede do RDS com cobertura de duas zonas de disponibilidade
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds_subnet"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}

# Instâncias EC2 na sub-rede pública
resource "aws_instance" "web_server" {
  ami           = "ami-04b70fa74e45c3917" # Substituir pelo ID da AMI desejada em us-west-2
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.ec2_sg.name]
  associate_public_ip_address = true
  count = 2
}
