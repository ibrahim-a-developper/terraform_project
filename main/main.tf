#provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.87.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform_dev"

}

#vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
}

#public subnet
resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.vpc.id
  for_each          = var.public_subnets
  cidr_block        = var.public_subnets[each.key]
  availability_zone = each.key
  tags = {
    Name          = "public_subnet_${each.key}"
    Environnement = "terraform"


  }
}

# create internet gateway for bublic route
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id


  tags = {
    Name          = "internet_gw"
    Environnement = "terraform"

  }
}

# public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name          = "public_rt"
    Environnement = "terraform"

  }
}

# association public route table 
resource "aws_route_table_association" "public_rt_association" {
  depends_on     = [aws_route_table.public_rt]
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}


#private subnet
resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.vpc.id
  for_each          = var.private_subnets
  cidr_block        = var.private_subnets[each.key]
  availability_zone = each.key
  tags = {
    Name          = "private_subnet_${each.key}"
    Environnement = "terraform"

  }
}

#eip
resource "aws_eip" "lb" {
  domain = "vpc"
}

#nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public_subnets["us-east-1a"].id
  tags = {
    Name          = "gw NAT"
    Environnement = "terraform"

  }
  depends_on = [aws_internet_gateway.gw]
}

# private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name          = "private_rt"
    Environnement = "terraform"

  }
}

# association private route table 
resource "aws_route_table_association" "private_rt_association" {
  depends_on     = [aws_route_table.private_rt]
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

#################
# Security Group
resource "aws_security_group" "WebSG" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id
  dynamic "ingress" {
    for_each = var.allow_ports
    iterator = port
    content {
      from_port = port.value
      to_port   = port.value
      protocol  = "tcp"
      # cidr_blocks = ["0.0.0.0/0"]
      security_groups = [aws_security_group.ALBSG.id]
    }
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name          = "allow_tls"
    Environnement = "terraform"
  }
}

#instance

resource "aws_instance" "instance" {
  for_each               = { "web" = "us-east-1a", "app" = "us-east-1b" }
  ami                    = "ami-053a45fff0a704a47"
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.WebSG.id]
  subnet_id              = aws_subnet.private_subnets[each.value].id
  # availability_zone      = each.value
  # associate_public_ip_address = true
  root_block_device {
    encrypted = true
  }
  # user_data = templatefile("httpd.sh", {
  #   server_name       = each.key
  #   availability_zone = each.value
  # })

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    echo 'This is server *${each.key}* in AWS Region US-EAST-1 in AZ ${each.value} ' > /var/www/html/index.html
  EOF
  tags = {
    Name          = "${each.key}_instance"
    Environnement = "terraform"

  }

}

#### Load Balancer
#  Security group for ALB
resource "aws_security_group" "ALBSG" {
  name        = "ALBSG"
  description = "security group for alb"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = "80"
    to_port     = "80"
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

#ALB
resource "aws_lb" "ALB" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALBSG.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
  tags = {
    Environment = "terraform"
  }
}

#target goup
resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# attachment
resource "aws_lb_target_group_attachment" "tg_attachement" {
  for_each = {
    for k, v in aws_instance.instance :
    k => v
  }

  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = each.value.id
  port             = 80
}

# create listner
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

#install EC2 Launch Configuration
resource "aws_launch_template" "launch_template" {
  # name        = "web_config"
  name_prefix = "Scaled_launch_instance"

  image_id               = "ami-053a45fff0a704a47"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.WebSG.id]


  lifecycle {
    create_before_destroy = true
  }
}

#auto scaling_group
resource "aws_autoscaling_group" "autoscaling_group" {
  name = "scalling_group"
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = [for subnet in aws_subnet.private_subnets : subnet.id]

  lifecycle {
    create_before_destroy = true
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "autoscaling_attachment_tg" {
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.id
  lb_target_group_arn    = aws_lb_target_group.target_group.arn
}

#################################
# rdb subnet group
resource "aws_db_subnet_group" "db_subnet" {
  name = "rdb_subnet_group"
  # subnet_ids = [aws_subnet.frontend.id, aws_subnet.backend.id]
  subnet_ids = [for subnet in aws_subnet.private_subnets : subnet.id]
  tags = {
    Name = "My DB subnet group"
  }
}

# security group
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "security group for RDS database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = [aws_security_group.WebSG.id]
  }


  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# database instance
resource "aws_db_instance" "rds_instance" {
  

  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  tags = {
    Name = "ExampleRDSServerInstance"
  }
}





