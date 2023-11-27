output "jenkins_public_url" {
  description = "Public URL to access Jenkins"
  value       = local.jenkins_public_url
}

output "controller_log_group" {
  description = "Jenkins controller log group"
  value       = aws_cloudwatch_log_group.jenkins_controller.name
}

output "agents_log_group" {
  description = "Jenkins agents log group"
  value       = aws_cloudwatch_log_group.agents.name
}

output "jenkins_credentials" {
  description = "Credentials to access Jenkins via the public URL"
  sensitive   = true
  value = {
    username = "admin"
    password = random_password.admin_password.result
  }
}

output "controller_config_on_s3" {
  description = "Jenkins controller configuration file on S3"
  value       = "s3://${aws_s3_object.jenkins_conf.bucket}/${aws_s3_object.jenkins_conf.key}"
}

output "ecr_images" {
  description = "ECR images when SOCI is enabled"
  value = var.soci.enabled ? {
    controller = "${aws_ecr_repository.jenkins_controller[0].repository_url}:${local.controller_docker_image_version}"
    agent      = "${aws_ecr_repository.jenkins_agent[0].repository_url}:${local.agent_docker_image_version}"
  } : null
}

output "ecs_events_log_group_name" {
  description = "ECS events log group"
  value       = var.soci.enabled ? module.ecs_events[0].log_group_name : null
}
