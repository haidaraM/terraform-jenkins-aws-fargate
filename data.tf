data "aws_caller_identity" "caller" {}

data "aws_route53_zone" "dns_zone" {
  count        = var.route53_zone_name != "" ? 1 : 0
  name         = var.route53_zone_name
  private_zone = false
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# see jenkins ecs plugin documentation: https://plugins.jenkins.io/scalable-amazon-ecs/
data "aws_iam_policy_document" "controller_ecs_task" {
  statement {
    sid    = "AllowToPassRoleToAgents"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.agents_ecs_execution_role.arn,
      aws_iam_role.agents_ecs_task_role.arn
    ]
  }

  statement {
    sid    = "S3AccessForJCasC"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${aws_s3_bucket.jenkins_conf_bucket.arn}/*"]
  }

  statement {
    sid    = "AllowECSAccess"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "TaskAccess"
    effect = "Allow"
    actions = [
      "ecs:StopTask",
      "ecs:ListContainerInstances",
    ]
    resources = [aws_ecs_cluster.cluster.arn]
  }

  statement {
    sid    = "RunTask"
    effect = "Allow"
    actions = [
      "ecs:RunTask",
    ]
    resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.caller.account_id}:task-definition/*"]
  }

  statement {
    sid    = "StopTask"
    effect = "Allow"
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]
    resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.caller.account_id}:task/*"]
  }
}