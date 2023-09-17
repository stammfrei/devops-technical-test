// The subnet for the ecs cluster
resource "aws_vpc" "ecs_wordpress" {
  cidr_block = var.cidr_block

  tags = {
    Name = "ecs-wordpress-${var.environment}"
  }
}

resource "aws_subnet" "wordpress_main_subnet" {
  vpc_id     = aws_vpc.ecs_wordpress.id
  cidr_block = var.main_subnet_cidr

  tags = {
    Name = "ecs-wordpress-${var.environment}-main-subnet"
  }
}

// Add a security group for managing firewall and routing
resource "aws_security_group" "ecs_wordpress" {
  name        = "ecs_wp_security_group"
  description = "Manage firewall rules for wordpresss"
  vpc_id      = aws_vpc.ecs_wordpress.id

  ingress {
    description = "Accept HTTP to VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Accept HTTPS to VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { // allow outgoing traffik
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
