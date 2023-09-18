// The subnet for the ecs cluster
resource "aws_vpc" "ecs_wordpress" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecs-wordpress-${var.environment}"
  }
}

resource "aws_subnet" "wordpress_main_subnet" {
  vpc_id            = aws_vpc.ecs_wordpress.id
  cidr_block        = var.main_subnet_cidr
  availability_zone = "eu-west-3a"

  tags = {
    Name = "ecs-wordpress-${var.environment}-main-subnet"
  }
}

resource "aws_subnet" "wordpress_secondary_subnet" {
  vpc_id            = aws_vpc.ecs_wordpress.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "eu-west-3b"

  tags = {
    Name = "ecs-wordpress-${var.environment}-secondary-subnet"
  }
}

resource "aws_internet_gateway" "wordpress" {
  vpc_id = aws_vpc.ecs_wordpress.id

  tags = {
    Name = "wordpress"
  }
}

resource "aws_default_route_table" "wordpress_egress" {
  default_route_table_id = aws_vpc.ecs_wordpress.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress.id
  }

  tags = {
    Name = "wordpres-${var.environment}-default-route"
  }
}

// Add a security group for managing firewall and routing
resource "aws_security_group" "ecs_wordpress" {
  name        = "ecs_wp_security_group"
  description = "Manage firewall rules for wordpresss"
  vpc_id      = aws_vpc.ecs_wordpress.id


  ingress { // open bar while we test things
    description = "Allow all incoming HTTP traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [
      aws_vpc.ecs_wordpress.cidr_block,
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "Allow all incoming HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.ecs_wordpress.cidr_block,
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "Accept inbound HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.ecs_wordpress.cidr_block,
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "Accept EFS mount ports inside VPC"
    from_port   = 2999
    to_port     = 2999
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.ecs_wordpress.cidr_block,
    ]
  }

  ingress {
    description = "Accept WP HTTP port inside VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.ecs_wordpress.cidr_block,
    ]
  }

  ingress {
    description = "Accept mysql port inside VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.ecs_wordpress.cidr_block,
    ]
  }

  egress {
    description      = "Allow all outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "wordpress-sg"
  }
}

resource "aws_s3_bucket" "wordpress_logs_lb" {
  bucket        = "wordpress-lb-logs-${var.environment}"
  force_destroy = true
}

resource "aws_lb" "wordpress_http" {
  name               = "wordpress-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.ecs_wordpress.id]
  subnets = [
    aws_subnet.wordpress_main_subnet.id,
    aws_subnet.wordpress_secondary_subnet.id,
  ]

  enable_deletion_protection = false

  // access_logs {
  //   bucket  = aws_s3_bucket.wordpress_logs_lb.id
  //   prefix  = "wordpress-lb-${var.environment}"
  //   enabled = true
  // }
}

resource "aws_lb_target_group" "wordpress" {
  name        = "wordpress-${var.environment}-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_wordpress.id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/healthcheck.html"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress_http.arn
  port              = "80"
  protocol          = "HTTP"
  // ssl_policy        = "ELBSecurityPolicy-2016-08"
  // certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}
