# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html
resource "aws_cloudwatch_event_rule" "task_state_change" {
  name        = "${var.name_prefix}-task-state-change"
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

# TODO: change the log group name and use cloudwatch resource policy
resource "aws_cloudwatch_log_group" "task_state_change" {
  name              = "/aws/events/${var.name_prefix}/task-state-change"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_target" "task_state_change" {
  rule = aws_cloudwatch_event_rule.task_state_change.name
  arn  = "${aws_cloudwatch_log_group.task_state_change.arn}:*"
}

resource "aws_cloudwatch_query_definition" "controller_task_state_change" {
  name            = "${var.name_prefix}/controller-start-time"
  log_group_names = [aws_cloudwatch_log_group.task_state_change.name]
  query_string    = <<Q
fields @timestamp, detail.containers.0.image, detail.createdAt,  detail.pullStartedAt, detail.pullStoppedAt, detail.startedAt, detail.desiredStatus, detail.lastStatus
| filter detail.group = 'service:jenkins-controller' and detail.desiredStatus = 'RUNNING' and detail.lastStatus = 'RUNNING'
| sort @timestamp desc
| limit 30
Q
}

resource "aws_cloudwatch_query_definition" "agent_task_state_change" {
  name            = "${var.name_prefix}/agent-start-time"
  log_group_names = [aws_cloudwatch_log_group.task_state_change.name]
  query_string    = <<Q
fields @timestamp, detail.containers.0.image, detail.createdAt,  detail.pullStartedAt, detail.pullStoppedAt, detail.startedAt, detail.desiredStatus, detail.lastStatus
| filter detail.group = 'family:fargate-example-template' and detail.desiredStatus = 'STOPPED' and detail.lastStatus = 'STOPPED'
| sort @timestamp desc
| limit 30
Q
}