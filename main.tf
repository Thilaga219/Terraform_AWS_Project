resource "aws_vpc" "vpc1" {
  cidr_block = var.cidr
}

# creation 2 public subnets
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

#creation of internet gateway to give netwrok access to resourcse inside subnets
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
}
#create rout table and define route rules
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
}
#associate route table with subnets
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt1.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt1.id
}

# create security group and attach and ingress and egress rules
resource "aws_security_group" "sg1" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  tags = {
    Name = "sg1"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#create S3 buckets
resource "aws_s3_bucket" "s31" {
  bucket = "thilaga123bucket" # need to globally unique
}
# craete  bucket(object) ownership controls(rule - policy)
resource "aws_s3_bucket_ownership_controls" "oc" {
  bucket = aws_s3_bucket.s31.id
  rule {
    object_ownership = "BucketOwnerPreferred" # files upload only owner owned 
  }
}
/*#apply acl only bucket owner has access
resource "aws_s3_bucket_acl" "acl1" {
  # depends on ensures ownwership controls applied before ACL
  depends_on = [aws_s3_bucket_ownership_controls.oc]

  bucket = aws_s3_bucket.s31.id
  acl    = "private"
}
*/

#craete 2 ec2 instance
resource "aws_instance" "web-server-1" {
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = base64encode(file("userdata.sh"))
}
resource "aws_instance" "web-server-2" {
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = base64encode(file("userdata1.sh"))
  #user_data_base64 = file("userdata1.sh")
}

#create ALB layer 7 and attach 2 subnets to ALB
resource "aws_lb" "alb1" {
  name               = "projalb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg1.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

}
# craete targate group that checks health of path
#TG defines where the load balancer should send traffic (your EC2 instances)
#ALB continuously checks if the instance is healthy before routing traffic.
resource "aws_lb_target_group" "tg" {
  name     = "mytg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}
#create target group attachemnets - that attach instances to target group
# Each block registers one EC2 instance with the Target Group.
# port defines the port on which ALB should send traffic to the instance (HTTP 80).
resource "aws_lb_target_group_attachment" "tgaattach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-server-1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tgaattach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-server-2.id
  port             = 80
}
# So now, both EC2 instances (web-server-1 and web-server-2) are registered as targets under the ALB.

#alb listens to port, defining rules
# Listener tells the ALB how to handle incoming traffic.
# means any request that comes in on port 80 will be forwarded to the target group (mytg).
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb1.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}
#So: User → ALB (port 80) → Target Group → EC2 instances

#output of load balancer DNS Name
output "loadbalancerdns" {
  value = aws_lb.alb1.dns_name
}