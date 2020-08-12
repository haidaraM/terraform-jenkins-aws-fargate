variable "efs_web_browser_listening_port" {
  type    = number
  default = 8000
}

resource "aws_cloudwatch_log_group" "efs_web_browser" {
  name              = "/efs-web-browser"
  retention_in_days = var.master_log_retention_days
  tags              = var.default_tags
}

resource "aws_ecs_task_definition" "efs_web_browser" {
  family                   = "efs-web-browser"
  execution_role_arn       = aws_iam_role.master_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.master_ecs_task_role.arn
  cpu                      = var.master_cpu_memory.cpu
  memory                   = var.master_cpu_memory.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  tags                     = var.default_tags

  volume {
    name = local.efs_volume_name

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.jenkins_conf.id
      root_directory = "/"
    }
  }

  container_definitions = templatefile("${path.module}/templates/efs-web-browser.template.json", {
    image          = "coderaiser/cloudcmd:14.7.2-alpine"
    container_port = var.efs_web_browser_listening_port
    region         = var.aws_region
    efs_mount_path = local.jenkins_home
    log_group_name = aws_cloudwatch_log_group.efs_web_browser.id
    env_vars = jsonencode([
      { name : "CLOUDCMD_NAME", value : "Jenkins Configuration Browser" },
      { name : "CLOUDCMD_CONFIG_AUTH", value : "false" },
      { name : "CLOUDCMD_AUTH", value : "true" },
      { name : "CLOUDCMD_USERNAME", value : "admin" },
      { name : "CLOUDCMD_PASSWORD", value : random_password.admin_password.result },
      { name : "CLOUDCMD_CONSOLE", value : "false" },
      { name : "CLOUDCMD_ROOT", value : local.jenkins_home },
      { name : "CLOUDCMD_ONE_FILE_PANEL", value : "true" },
    ])
    efs_volume_name = local.efs_volume_name
  })
}

resource "aws_ecs_service" "efs_web_browser" {
  name             = "efs-web-browser"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.efs_web_browser.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = var.fargate_platform_version
  tags             = var.default_tags

  network_configuration {
    security_groups  = [aws_security_group.efs_web_browser.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  # alb http target group
  load_balancer {
    target_group_arn = aws_alb_target_group.efs_web_browser.arn
    container_name   = "cloud-cmd"
    container_port   = var.efs_web_browser_listening_port
  }
}

resource "aws_security_group" "efs_web_browser" {
  name        = "sgr-efs-web-browser"
  description = "Web browser for EFS"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" : "sgr-efs-web-browser" }, var.default_tags)
}

resource "aws_security_group_rule" "efs_web_browser_egress_all" {
  security_group_id = aws_security_group.efs_web_browser.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "efs_web_browser_ingress_alb" {
  security_group_id        = aws_security_group.efs_web_browser.id
  from_port                = var.efs_web_browser_listening_port
  to_port                  = var.efs_web_browser_listening_port
  protocol                 = "tcp"
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_security_group.id
  description              = "From ALB to EFS web browser"
}

resource "aws_alb_target_group" "efs_web_browser" {
  name        = "alb-http-efs-web-browser"
  port        = var.efs_web_browser_listening_port
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  tags        = var.default_tags

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "efs_web_browser" {
  load_balancer_arn = aws_alb.alb_jenkins_master.arn
  port              = "8000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.efs_web_browser.arn
  }
}