output "jenkins_public_url" {
  value = local.jenkins_public_url
}

output "master_log_group" {
  value = aws_cloudwatch_log_group.jenkins_master.name
}

output "agents_log_group" {
  value = aws_cloudwatch_log_group.agents.name
}

output "jenkins_credentials" {
  value = {
    username = "admin"
    password = random_password.admin_password.result
  }
}

output "master_config_on_s3" {
  value = "s3://${aws_s3_bucket_object.jenkins_conf.bucket}/${aws_s3_bucket_object.jenkins_conf.key}"
}