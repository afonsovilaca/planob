# File instalation docker
#resource "template_file" "docker-userdata" {
#    template = "${file("install-docker.sh")}"
#}
 data "template_file" "docker-userdata" {
  template = "${file("install-docker.sh")}"
}

# File instalation java
data "template_file" "zkk-userdata" {
    template = "${file("install_zk_cluster_common.sh")}"
}

# File instalation zk1
data "template_file" "zkk1" {
    template = "${file("install_zk_cluster_1.sh")}"
}

# File instalation zk2
data "template_file" "zkk2" {
    template = "${file("install_zk_cluster_2.sh")}"
}

# File instalation zk3
data "template_file" "zkk3" {
    template = "${file("install_zk_cluster_3.sh")}"
}


# Instalation per aws
data "template_cloudinit_config" "zk1" {
  gzip          = true
  base64_encode = true

 part {
   content_type = "text/x-shellscript"
   content      = "${data.template_file.zkk-userdata.rendered}"
 }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.zkk1.rendered}"
  }
}

# Instalation per aws
data "template_cloudinit_config" "zk2" {
  gzip          = true
  base64_encode = true

 part {
   content_type = "text/x-shellscript"
   content      = "${data.template_file.zkk-userdata.rendered}"
 }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.zkk2.rendered}"
  }
}

# Instalation per aws
data "template_cloudinit_config" "zk3" {
  gzip          = true
  base64_encode = true

 part {
   content_type = "text/x-shellscript"
   content      = "${data.template_file.zkk-userdata.rendered}"
 }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.zkk3.rendered}"
  }
}


# Create VPC class C maximum 8 subnets 32 hosts each (30 usable)

resource "aws_vpc" "vpc_isep_sem_21" {
  cidr_block           = "172.31.0.0/24"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_sem"
  }
}

# Create Subnets

resource "aws_subnet" "vpc_isep_sem_21_0" {
  vpc_id                  = aws_vpc.vpc_isep_sem_21.id
  cidr_block              = "172.31.0.32/27"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "vpc_isep_sem_21_subnet_0"
  }
}

resource "aws_subnet" "vpc_isep_sem_21_1" {
  vpc_id                  = aws_vpc.vpc_isep_sem_21.id
  cidr_block              = "172.31.0.64/27"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "vpc_isep_sem_21_subnet_1"
  }
}

resource "aws_subnet" "vpc_isep_sem_21_2" {
  vpc_id                  = aws_vpc.vpc_isep_sem_21.id
  cidr_block              = "172.31.0.96/27"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"
  tags = {
    Name = "vpc_isep_sem_21_subnet_2"
  }
}

resource "aws_subnet" "vpc_isep_sem_21_3" {
  vpc_id                  = aws_vpc.vpc_isep_sem_21.id
  cidr_block              = "172.31.0.128/27"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1d"
  tags = {
    Name = "vpc_isep_sem_21_subnet_3"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "igw_isep_sem" {
  vpc_id = aws_vpc.vpc_isep_sem_21.id
}

# Route table: attach Internet Gateway
resource "aws_route_table" "public_rt_isep_sem" {
  vpc_id = aws_vpc.vpc_isep_sem_21.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_isep_sem.id
  }
}

# Route table association with public subnets
resource "aws_route_table_association" "public-subnet-isep_sem_0" {
  subnet_id      = aws_subnet.vpc_isep_sem_21_0.id
  route_table_id = aws_route_table.public_rt_isep_sem.id
}

resource "aws_route_table_association" "public-subnet-isep_sem_1" {
  subnet_id      = aws_subnet.vpc_isep_sem_21_1.id
  route_table_id = aws_route_table.public_rt_isep_sem.id
}

resource "aws_route_table_association" "public-subnet-isep_sem_2" {
  subnet_id      = aws_subnet.vpc_isep_sem_21_2.id
  route_table_id = aws_route_table.public_rt_isep_sem.id
}

resource "aws_route_table_association" "public-subnet-isep_sem_3" {
  subnet_id      = aws_subnet.vpc_isep_sem_21_3.id
  route_table_id = aws_route_table.public_rt_isep_sem.id
}

# Security Groups
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc_isep_sem_21.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Zookeeper port"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka port"
    from_port   = 9092
    to_port     = 9092
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
    Name = "allow_ssh"
  }

}


# Create 3 instance for kafka / Zookeeper in 3 distinct az for high availability
# Key pair already created in AWS

resource "aws_instance" "kafka_broker1" {
  ami = "ami-00e87074e52e6c9f9"
  instance_type = "t2.micro"
  availability_zone  = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.vpc_isep_sem_21_0.id
  private_ip = "172.31.0.49"
  associate_public_ip_address = true
  key_name = "clusterkafka"
  user_data = "${data.template_cloudinit_config.zk1.rendered}" 
  tags = {name="zkafkab1"}

}

resource "aws_instance" "kafka_broker2" {
  ami = "ami-00e87074e52e6c9f9"
  instance_type = "t2.micro"
  availability_zone  = "us-east-1b"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.vpc_isep_sem_21_1.id
    private_ip = "172.31.0.87"
  associate_public_ip_address = true
  key_name = "clusterkafka"
  user_data = "${data.template_cloudinit_config.zk2.rendered}" 
  tags = {name="zkafkab2"}

}

resource "aws_instance" "kafka_broker3" {
 ami = "ami-00e87074e52e6c9f9"
  instance_type = "t2.micro"
  availability_zone  = "us-east-1c"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.vpc_isep_sem_21_2.id
  private_ip = "172.31.0.107"
  associate_public_ip_address = true
  key_name = "clusterkafka"
  user_data = "${data.template_cloudinit_config.zk3.rendered}" 
  tags = {name="zkafkab3"}
  
}

# Resource docker for management tools
resource "aws_instance" "docker" {
 ami = "ami-00e87074e52e6c9f9"
  instance_type = "t2.micro"
  availability_zone  = "us-east-1d"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.vpc_isep_sem_21_3.id
  private_ip = "172.31.0.131"
  associate_public_ip_address = true
  key_name = "clusterkafka"
  #user_data = "${template_file.docker-userdata.rendered}"
  user_data = "${data.template_file.docker-userdata.rendered}" # Testar este amanha
  tags = {name="docker"}
  
}