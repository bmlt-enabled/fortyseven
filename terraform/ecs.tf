resource "aws_ecs_task_definition" "this" {
  family             = "fortyseven"
  task_role_arn      = "arn:aws:iam::766033189774:role/ecs-exec-task-role"
  execution_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode(
    [
      {
        name              = "fortyseven",
        volumesFrom       = [],
        extraHosts        = null,
        dnsServers        = null,
        disableNetworking = null,
        dnsSearchDomains  = null,
        portMappings = [
          {
            containerPort = 8080,
            protocol      = "tcp"
          }
        ],
        hostname              = null,
        essential             = true,
        mountPoints           = [],
        ulimits               = null,
        dockerSecurityOptions = null,
        environment = [
          {
            name  = "ADAPTER",
            value = "slack"
          },
          {
            name  = "HUBOT_NAME",
            value = "47"
          },
          {
            name  = "HUBOT_SLACK_RTM_CLIENT_OPTS",
            value = "{\"useRtmConnect\": \"true\"}"
          }
        ],
        secrets = [
          {
            "valueFrom" : aws_ssm_parameter.hubot_slack_token.arn,
            "name" : "HUBOT_SLACK_TOKEN"
          }
        ],
        links                  = [],
        workingDirectory       = "/opt",
        readonlyRootFilesystem = null,
        image                  = "766033189774.dkr.ecr.us-east-1.amazonaws.com/fortyseven:latest",
        user                   = null,
        dockerLabels           = null,
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.name,
            awslogs-region        = "us-east-1",
            awslogs-stream-prefix = "47-bot"
          }
        },
        memoryReservation = 128,
        privileged        = null,
        linuxParameters = {
          initProcessEnabled = true
        }
      }
    ]
  )
}

resource "aws_ecs_service" "this" {
  name                               = "fortyseven"
  cluster                            = "bmlt"
  desired_count                      = 1
  iam_role                           = aws_iam_role.this.name
  task_definition                    = aws_ecs_task_definition.this.arn
  enable_execute_command             = true
  deployment_minimum_healthy_percent = 100

  load_balancer {
    target_group_arn = aws_alb_target_group.this.id
    container_name   = "fortyseven"
    container_port   = 8080
  }
}

resource "aws_alb_target_group" "this" {
  name     = "fortyseven"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  deregistration_delay = 60

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = data.aws_lb_listener.main_443.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.this.arn
  }

  condition {
    host_header {
      values = ["fortyseven.aws.bmlt.app"]
    }
  }
}

resource "aws_iam_role" "this" {
  name = "fortyseven"

  assume_role_policy = jsonencode(
    {
      Version = "2008-10-17",
      Statement = [
        {
          Sid    = "",
          Effect = "Allow",
          Principal = {
            Service = "ecs.amazonaws.com"
          },
          Action = "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "this" {
  name = aws_iam_role.this.name
  role = aws_iam_role.this.name

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ec2:Describe*",
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:Describe*",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "elasticloadbalancing:RegisterTargets"
          ],
          Resource = "*"
        }
      ]
    }
  )
}


resource "aws_cloudwatch_log_group" "this" {
  name              = "fortyseven"
  retention_in_days = 14
}



data "aws_iam_policy_document" "ecs_task_role_assume_policy" {
  statement {
    sid    = "ecsTask"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecs_execute_command" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_execute_command" {
  name        = "ecs-execute-command-47"
  description = "Allows execution of remote commands on ECS"
  policy      = data.aws_iam_policy_document.ecs_execute_command.json
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs-exec-task-role-47"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_policy.json

  tags = { Name = "ecs-exec-task-role-47" }
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_execute_command_attachment" {
  policy_arn = aws_iam_policy.ecs_execute_command.arn
  role       = aws_iam_role.ecs_task_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_execution_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_role.name
}

resource "aws_ssm_parameter" "hubot_slack_token" {
  name  = "HUBOT_SLACK_TOKEN"
  type  = "String"
  value = "UPDATE_IN_CONSOLE_MANUALLY"

  lifecycle {
    ignore_changes = [value]
  }
}
