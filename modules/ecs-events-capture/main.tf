locals {
  cluster_name = replace(data.aws_arn.ecs_cluster.resource, "cluster/", "")
}

data "aws_arn" "ecs_cluster" {
  arn = var.cluster_arn
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html
resource "aws_cloudwatch_event_rule" "task_state_change" {
  name        = "${local.cluster_name}-task-state-change"
  description = "Rule listening to ECS Task State Change events"
  event_pattern = jsonencode({
    source      = ["aws.ecs"],
    detail-type = ["ECS Task State Change"],
    detail = {
      clusterArn = [var.cluster_arn]
      /*
      We only care aboute the following states for now. They contain all the fields that we need to get the start time.
      Remove them if you want to listen to all state changes.
      */
      lastStatus    = ["RUNNING"]
      desiredStatus = ["RUNNING"]
    }
  })
}

resource "aws_cloudwatch_log_group" "task_state_change" {
  name              = "/aws/events/${local.cluster_name}/task-state-change"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_target" "task_state_change" {
  rule = aws_cloudwatch_event_rule.task_state_change.name
  arn  = "${aws_cloudwatch_log_group.task_state_change.arn}:*"
}
