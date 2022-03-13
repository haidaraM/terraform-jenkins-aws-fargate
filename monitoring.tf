resource "aws_sns_topic" "alarms_topic" {
  name         = "jenkins-alarms"
  display_name = "Topic for Jenkins alarms"
}

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance" {
  alarm_name          = "jenkins-efs-low-burst-credits-balance"
  alarm_description   = "Alarm triggered when BURST's credit has reached half of the credit allocated by AWS which is 2.1TiB"
  comparison_operator = "LessThanThreshold"
  namespace           = "AWS/EFS"
  metric_name         = "BurstCreditBalance"
  statistic           = "Minimum"
  evaluation_periods  = 1  # 1 minute
  period              = 60 # 1 minute
  threshold           = var.efs_burst_credit_balance_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]
  ok_actions          = [aws_sns_topic.alarms_topic.arn]

  dimensions = {
    FileSystemId = aws_efs_file_system.jenkins_conf.id
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_too_many_5xx_errors" {
  alarm_name          = "jenkins-alb-too-many-5xx-errors"
  alarm_description   = "The number of 5xx errors recorded by the Controller ALB is high. Check the log group ${aws_cloudwatch_log_group.jenkins_controller.name}."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  evaluation_periods  = 5  # 5 minutes
  period              = 60 # 1 minute
  threshold           = 60
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]
  ok_actions          = [aws_sns_topic.alarms_topic.arn]

  dimensions = {
    LoadBalancer = aws_alb.alb_jenkins_controller.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy_host_count" {
  alarm_name          = "jenkins-alb-no-healthy-target"
  alarm_description   = "No healthy target registered in the ALB."
  comparison_operator = "LessThanThreshold"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Average"
  evaluation_periods  = 5  # 5 minutes
  period              = 60 # 1 minute
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]
  ok_actions          = [aws_sns_topic.alarms_topic.arn]

  dimensions = {
    TargetGroup  = aws_alb_target_group.jenkins_controller_tg.arn_suffix
    LoadBalancer = aws_alb.alb_jenkins_controller.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "jenkins_high_cpu" {
  alarm_name          = "jenkins-controller-high-cpu-utilization"
  alarm_description   = "High CPU utilization of the Jenkins Controller"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  evaluation_periods  = 5  # 5 minutes
  period              = 60 # 1 minute
  threshold           = 80 # %
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]
  ok_actions          = [aws_sns_topic.alarms_topic.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.jenkins_controller.name
  }
}


resource "aws_cloudwatch_metric_alarm" "jenkins_high_memory" {
  alarm_name          = "jenkins-controller-high-memory-utilization"
  alarm_description   = "High Memory utilization of the Jenkins Controller"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  evaluation_periods  = 5  # 5 minutes
  period              = 60 # 1 minute
  threshold           = 75 # %
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]
  ok_actions          = [aws_sns_topic.alarms_topic.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.jenkins_controller.name
  }
}

resource "aws_cloudwatch_log_group" "jenkins_controller" {
  name              = "/jenkins/controller"
  retention_in_days = var.controller_log_retention_days
}

resource "aws_cloudwatch_log_group" "agents" {
  name              = "/jenkins/agents"
  retention_in_days = var.agents_log_retention_days
}
