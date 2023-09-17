locals {
  db_name = "wordpress-${var.environment}"
}

resource "aws_db_instance" "wordpress" {
  allocated_storage    = var.db_allocated_storage
  db_name              = local.db_name
  engine               = "mysql"
  engine_version       = var.db_mysql_version
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = var.parameter_group_name
}
