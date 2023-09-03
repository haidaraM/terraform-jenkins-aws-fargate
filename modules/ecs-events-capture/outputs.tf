output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group containing the ECS events"
  value       = aws_cloudwatch_log_group.task_state_change.name
}
