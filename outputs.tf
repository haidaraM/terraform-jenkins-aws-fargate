output "jenkins_public_url" {
  value = local.jenkins_public_url
}

output "controller_log_group" {
  value = aws_cloudwatch_log_group.jenkins_controller.name
}

output "agents_log_group" {
  value = aws_cloudwatch_log_group.agents.name
}

output "jenkins_credentials" {
  sensitive = true
  value = {
    username = "admin"
    password = random_password.admin_password.result
  }
}

output "controller_config_on_s3" {
  value = "s3://${aws_s3_object.jenkins_conf.bucket}/${aws_s3_object.jenkins_conf.key}"
}