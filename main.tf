terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.68"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  jenkins_master_container_name = "jenkins-master"
  jenkins_home                  = "/var/jenkins_home" # Jenkins home inside the container. This is hard coded in the official docker image
  efs_volume_name               = "jenkins-efs-configuration"
  jenkins_host                  = "${var.route53_subdomain}.${var.route53_zone_name}"
  jenkins_public_url            = var.route53_zone_name != "" ? "https://${local.jenkins_host}" : "http://${aws_alb.alb_jenkins_master.dns_name}"
}

data "aws_caller_identity" "caller" {}

data "aws_route53_zone" "dns_zone" {
  count        = var.route53_zone_name != "" ? 1 : 0
  name         = var.route53_zone_name
  private_zone = false
}

# The cluster for Jenkins Master and agents
resource "aws_ecs_cluster" "cluster" {
  name               = "jenkins-cluster"
  capacity_providers = ["FARGATE"]
  tags               = var.default_tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "jenkins_master" {
  name              = "/jenkins/master"
  retention_in_days = var.master_log_retention_days
  tags              = var.default_tags
}

resource "aws_cloudwatch_log_group" "agents" {
  name              = "/jenkins/agents"
  retention_in_days = var.agents_log_retention_days
  tags              = var.default_tags
}

resource "aws_efs_file_system" "jenkins_conf" {
  performance_mode                = var.efs_performance_mode
  throughput_mode                 = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput_in_mibps
  tags                            = merge({ "Name" : "jenkins-master-configuration" }, var.default_tags)

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "mount_targets" {
  for_each        = var.private_subnets
  file_system_id  = aws_efs_file_system.jenkins_conf.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_ecs_task_definition" "jenkins_master" {
  family                   = "jenkins-master"
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

  container_definitions = templatefile("${path.module}/templates/ecs-task.template.json", {
    image             = var.master_docker_image
    region            = var.aws_region
    log_group_name    = aws_cloudwatch_log_group.jenkins_master.id
    jenkins_http_port = var.master_listening_port
    jenkins_jnlp_port = var.master_jnlp_port
    env_vars = jsonencode([
      { name : "JAVA_OPTS", value : var.master_java_opts },
      { name : "JENKINS_CONF_S3_URL", value : "s3://${aws_s3_bucket_object.jenkins_conf.bucket}/${aws_s3_bucket_object.jenkins_conf.key}" },
      # This will force the creation of a new version of the task definition if the configuration changes and cause ECS to launch
      # a new container.
      { name : "JENKINS_CONF_S3_VERSION_ID", value : aws_s3_bucket_object.jenkins_conf.version_id }
    ])
    jenkins_master_container_name = local.jenkins_master_container_name
    efs_volume_name               = local.efs_volume_name
    jenkins_user_uid              = var.master_docker_user_uid_gid
    jenkins_home                  = local.jenkins_home
  })
}

resource "aws_ecs_service" "jenkins_master" {
  name             = "jenkins-master"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.jenkins_master.arn
  desired_count    = 1 # only one master should be up and running. Open Source version of Jenkins is not adapted for multi masters mode
  launch_type      = "FARGATE"
  platform_version = var.fargate_platform_version
  tags             = var.default_tags

  deployment_minimum_healthy_percent = var.master_deployment_percentages.min
  deployment_maximum_percent         = var.master_deployment_percentages.max

  network_configuration {
    security_groups  = [aws_security_group.jenkins_master_sg.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  # alb http target group
  load_balancer {
    target_group_arn = aws_alb_target_group.jenkins_master_tg.arn
    container_name   = local.jenkins_master_container_name
    container_port   = var.master_listening_port
  }

  # nlb http for agent
  load_balancer {
    target_group_arn = aws_lb_target_group.nlb_agents_to_master_http.arn
    container_name   = local.jenkins_master_container_name
    container_port   = var.master_listening_port
  }

  # nlb jnlp for agent
  load_balancer {
    target_group_arn = aws_lb_target_group.nlb_agents_to_master_jnlp.arn
    container_name   = local.jenkins_master_container_name
    container_port   = var.master_jnlp_port
  }

  # the listeners that attach the target groups to the load balancers need to be created first. Otherwise, there will
  # be an error saying that the target group is not attached to a load balancer.
  depends_on = [
    aws_lb_listener.master_http,
    aws_lb_listener.master_https,
    aws_lb_listener.agents_http_listener,
    aws_lb_listener.agents_jnlp_listener
  ]
}

############ Route53 and ACM
resource "aws_acm_certificate" "master_certificate" {
  count             = var.route53_zone_name != "" ? 1 : 0
  domain_name       = local.jenkins_host
  validation_method = "DNS"
  tags              = merge({ Name = local.jenkins_host }, var.default_tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation_record" {
  count   = var.route53_zone_name != "" ? 1 : 0
  name    = list(aws_acm_certificate.master_certificate.0.domain_validation_options)[0].resource_record_name
  type    = list(aws_acm_certificate.master_certificate.0.domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.dns_zone.0.zone_id
  records = [list(aws_acm_certificate.master_certificate.0.domain_validation_options)[0].resource_record_value]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "validation" {
  count                   = var.route53_zone_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.master_certificate.0.arn
  validation_record_fqdns = list(aws_route53_record.certificate_validation_record.0.fqdn)
}

resource "aws_route53_record" "alb_dns_record" {
  count   = var.route53_zone_name != "" ? 1 : 0
  name    = local.jenkins_host
  type    = "A"
  zone_id = data.aws_route53_zone.dns_zone.0.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_alb.alb_jenkins_master.dns_name
    zone_id                = aws_alb.alb_jenkins_master.zone_id
  }
}