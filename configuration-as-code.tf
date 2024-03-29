locals {
  agent_docker_image_version = split(":", var.agent_docker_image)[1]
  agent_docker_image         = var.soci.enabled ? "${aws_ecr_repository.jenkins_agent[0].repository_url}:${local.agent_docker_image_version}" : var.agent_docker_image

  controller_docker_image_version = split(":", var.controller_docker_image)[1]
  controller_docker_image         = var.soci.enabled ? "${aws_ecr_repository.jenkins_controller[0].repository_url}:${local.controller_docker_image_version}" : var.controller_docker_image

  jcas = templatefile("${path.module}/templates/jcasc.template.yml", {
    ecs_cluster_arn                  = aws_ecs_cluster.cluster.arn
    region_name                      = var.aws_region
    agents_sg_ids                    = join(",", [aws_security_group.jenkins_agents.id])
    agents_subnet_ids                = join(",", var.private_subnets)
    agents_log_group                 = aws_cloudwatch_log_group.agents.name
    agents_execution_role_arn        = aws_iam_role.agents_ecs_execution_role.arn
    agents_task_role_arn             = aws_iam_role.agents_ecs_task_role.arn
    example_agent_label              = "example-agent"
    example_agent_cpu_memory         = var.agents_cpu_memory
    example_agent_docker_image       = local.agent_docker_image
    jnlp_port                        = var.controller_jnlp_port
    jenkins_controller_num_executors = var.controller_num_executors
    jenkins_public_url               = local.jenkins_public_url
    jenkins_private_url              = "http://${aws_service_discovery_service.service_discovery.name}.${aws_service_discovery_private_dns_namespace.namespace.name}:${var.controller_listening_port}/"
    fargate_platform_version         = var.fargate_platform_version
    admin_password                   = random_password.admin_password.result
  })
}

# Password for Jenkins admin user
resource "random_password" "admin_password" {
  length  = 16
  special = true
}

resource "aws_s3_bucket" "jenkins_conf_bucket" {
  bucket        = "jenkins-jcasc-${data.aws_caller_identity.caller.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.jenkins_conf_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "conf_bucket" {
  bucket = aws_s3_bucket.jenkins_conf_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

/*
 Note: AWS recommends that you wait for 15 minutes after enabling versioning before issuing write operations (PUT or DELETE)
  on objects in the bucket.
 Do not forget that when creating this stack the first time.
*/
resource "aws_s3_object" "jenkins_conf" {
  bucket       = aws_s3_bucket_versioning.conf_bucket.bucket
  key          = "jenkins-conf.yml"
  acl          = "private"
  content_type = "application/x-yaml"
  etag         = md5(local.jcas) # Used to force the update of the object version id when the configuration changes
  content      = local.jcas
}
