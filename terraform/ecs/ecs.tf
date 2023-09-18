// Cluster creation
resource "aws_ecs_cluster" "wordpress" {
  name = "wp-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.wordpress.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.wordpress.name
      }
    }
  }
}

// Set capacity providers
resource "aws_ecs_cluster_capacity_providers" "wordpress_fargate" {
  cluster_name = aws_ecs_cluster.wordpress.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
  ]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

// add logging with cloudwatch
resource "aws_kms_key" "wordpress" {
  description             = "wordpress cluster kms key"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "wordpress" {
  name = "wordpress-cloudwatch-${var.environment}"
}

resource "aws_iam_role" "wordpress_task_role" {
  name = "wordpress-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "lambda.amazonaws.com",
            "ecr.amazonaws.com",
          ]
        }
      },
    ]
  })

  inline_policy {
    name = "ecs-task-permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:*",
            "ecs:*",
            "logs:*",
            "ssm:*",
            "kms:Decrypt",
            "secretsmanager:GetSecretValue",
            "iam:PassRole",
          ]

          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    managedBy = "terraform"
  }
}

resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  task_role_arn            = aws_iam_role.wordpress_task_role.arn
  execution_role_arn       = aws_iam_role.wordpress_task_role.arn
  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.image
      essential = true

      mountPoints = [
        {
          sourceVolume  = "wp-content"
          containerPath = "/var/www/html"
        }
      ]

      environment = [
        { name  = "WP_DB_NAME"
          value = local.db_name
        },
        { name  = "WP_DB_USER"
          value = var.db_username
        },
        { name  = "WP_DB_PASSWORD"
          value = var.db_password
        },
        { name  = "WP_DB_HOST"
          value = aws_db_instance.wordpress.address
        },
        { name  = "WP_INIT_FOLDER"
          value = "${tostring(var.wp_folder_reset)}"
        },
        { name  = "WP_RESET_CONFIG"
          value = "${tostring(var.wp_config_reset)}"
        },
      ]

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.wordpress.name,
          awslogs-region        = "eu-west-3",
          awslogs-stream-prefix = "awslogs-wordpress-${var.environment}"
        }
      }
    }
  ])

  volume {
    name = "wp-content"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.wp_content.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999

      authorization_config {
        access_point_id = aws_efs_access_point.wp_content.id
      }
    }
  }

}

resource "aws_efs_file_system" "wp_content" {
  tags = {
    Name = "wp-content-${var.environment}"
  }
}

resource "aws_efs_mount_target" "wp_content" {
  file_system_id  = aws_efs_file_system.wp_content.id
  subnet_id       = aws_subnet.wordpress_main_subnet.id
  security_groups = [aws_security_group.ecs_wordpress.id]
}

resource "aws_efs_access_point" "wp_content" {
  file_system_id = aws_efs_file_system.wp_content.id

  root_directory {
    path = "/wp-content"

    creation_info {
      owner_uid   = "33"
      owner_gid   = "33"
      permissions = "0777"
    }
  }

  posix_user {
    uid = "33"
    gid = "33"
  }
}

resource "aws_ecs_service" "wordpress" {
  name            = "wordpress"
  cluster         = aws_ecs_cluster.wordpress.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1

  force_new_deployment   = true
  enable_execute_command = true

  launch_type = "FARGATE"

  load_balancer {
    container_name   = local.container_name
    container_port   = 8080
    target_group_arn = aws_lb_target_group.wordpress.arn
  }

  network_configuration {
    security_groups = [aws_security_group.ecs_wordpress.id]
    subnets = [
      aws_subnet.wordpress_main_subnet.id,
      aws_subnet.wordpress_secondary_subnet.id,
    ]
    assign_public_ip = true // it seems required to pull from ecr, wtf ?
  }
}
