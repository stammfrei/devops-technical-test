locals {
  db_name = "wordpress_${var.environment}"
}

resource "aws_db_subnet_group" "wordpress" {
  name       = "wordpress"
  subnet_ids = [aws_subnet.wordpress_main_subnet.id, aws_subnet.wordpress_secondary_subnet.id]

  tags = {
    Name = "Subnet group linked to wordpress"
  }
}

resource "aws_db_instance" "wordpress" {
  allocated_storage      = var.db_allocated_storage
  db_name                = local.db_name
  engine                 = "mysql"
  engine_version         = var.db_mysql_version
  instance_class         = var.db_instance_class
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = var.db_parameter_group_name
  apply_immediately      = var.environment == "prod" ? false : true
  skip_final_snapshot    = var.environment == "prod" ? false : true
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [aws_security_group.ecs_wordpress.id]
  publicly_accessible    = false

  tags = {
    Name = "wordpress-database"
  }
}
