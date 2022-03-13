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