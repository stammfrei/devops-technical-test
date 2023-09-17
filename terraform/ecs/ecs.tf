locals {
  container_name = "whoami"
}

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

resource "aws_iam_role" "wordpress" {
  name = "wordpress-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Effect" : "Allow",
          "Sid" : ""
          "Principal" : {
            "Service" : [
              "ecs.amazonaws.com",
              "ecs-tasks.amazonaws.com",
              "ecr.amazonaws.com",
            ]
          },
        }
      ]
    }
  )

  managed_policy_arns = [aws_iam_policy.wordpress_role_allow_ecr.arn]

  tags = {
    managedBy = "terraform"
  }
}

resource "aws_iam_policy" "wordpress_role_allow_ecr" {
  name = "wordpress-allow-ecr-ecs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [ // open bar permissions for now
          "ecr:*",
          "ecs:*",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:ListTopics",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  task_role_arn            = aws_iam_role.wordpress.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "wordpress" {
  name            = "wordpress"
  cluster         = aws_ecs_cluster.wordpress.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.wordpress_main_subnet.id]
    security_groups  = [aws_security_group.ecs_wordpress.id]
    assign_public_ip = true
  }
}
