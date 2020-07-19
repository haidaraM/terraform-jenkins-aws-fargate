locals {
  jcas = templatefile("${path.module}/templates/jcasc.template.yml", {
    ecs_cluster_arn              = aws_ecs_cluster.cluster.arn
    region_name                  = var.aws_region
    agents_sg_ids                = join(",", [aws_security_group.jenkins_agents.id])
    agents_subnet_ids            = join(",", var.private_subnets)
    agents_log_group             = aws_cloudwatch_log_group.agents.name
    agents_execution_role_arn    = aws_iam_role.agents_ecs_execution_role.arn
    agents_task_role_arn         = aws_iam_role.agents_ecs_task_role.arn
    example_agent_label          = "example-agent"
    example_agent_cpu_memory     = var.example_agent_cpu_memory
    example_agent_docker_image   = var.example_agent_docker_image
    jnlp_port                    = var.master_jnlp_port
    jenkins_master_num_executors = var.master_num_executors
    jenkins_public_url           = local.jenkins_public_url
    jenkins_nlb_url              = "http://${aws_lb.nlb_agents.dns_name}"
    fargate_platform_version     = var.fargate_platform_version
    admin_password               = random_password.admin_password.result
  })
}

# Password for Jenkins admin user
resource "random_password" "admin_password" {
  length  = 16
  special = true
}

resource "aws_s3_bucket" "jenkins_conf_bucket" {
  bucket        = "jenkins-jcasc-${data.aws_caller_identity.caller.account_id}"
  acl           = "private"
  force_destroy = true
  tags          = var.default_tags

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "jenkins_conf" {
  bucket       = aws_s3_bucket.jenkins_conf_bucket.bucket
  key          = "jenkins-conf.yml"
  acl          = "private"
  content_type = "application/x-yaml"
  etag         = md5(local.jcas) # Used to force the update of the object version id when the configuration changes
  content      = local.jcas
  tags         = var.default_tags
}
