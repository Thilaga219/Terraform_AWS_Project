
# VPC
resource "aws_vpc" "vpc1" {
  cidr_block = var.cidr
  tags = {
    Name = "my_vpc"
  }
}

# Public subnets
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Private subnets
resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id
}

# Public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate public subnets
resource "aws_route_table_association" "public_rta1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway in public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id
}

# Private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
}

# Associate private subnets
resource "aws_route_table_association" "private_rta1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security group
resource "aws_security_group" "sg1" {
  name        = "allow_tls"
  description = "Allow inbound HTTP/SSH, all outbound"
  vpc_id      = aws_vpc.vpc1.id

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

# Application Load Balancer (ALB)
resource "aws_lb" "alb" {
  name               = "projalb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg1.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
}

# Target group for private apps
resource "aws_lb_target_group" "tg" {
  name     = "private-apps-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id

  health_check {
    path = "/"
  }
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

# Launch Templates
resource "aws_launch_template" "app1" {
  name_prefix   = "app1-"
  image_id      = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  user_data = base64encode(file("userdata1.sh"))
}

resource "aws_launch_template" "app2" {
  name_prefix   = "app2-"
  image_id      = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  user_data = base64encode(file("userdata.sh"))
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "asg_app1" {
  vpc_zone_identifier = [aws_subnet.private1.id]
  launch_template {
    id      = aws_launch_template.app1.id
    version = "$Latest"
  }
  min_size           = 1
  max_size           = 2
  desired_capacity   = 1
  target_group_arns  = [aws_lb_target_group.tg.arn]
}

resource "aws_autoscaling_group" "asg_app2" {
  vpc_zone_identifier = [aws_subnet.private2.id]
  launch_template {
    id      = aws_launch_template.app2.id
    version = "$Latest"
  }
  min_size           = 1
  max_size           = 2
  desired_capacity   = 1
  target_group_arns  = [aws_lb_target_group.tg.arn]
}

# Output ALB DNS
output "loadbalancerdns" {
  value = aws_lb.alb.dns_name
}
