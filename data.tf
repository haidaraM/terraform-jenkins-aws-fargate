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

# See jenkins ecs plugin documentation: https://plugins.jenkins.io/scalable-amazon-ecs/
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

# Getting the network interface attached to the nlb. Their IP address will be used in the security group attached to the
# task according to the best practice
# https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-register-targets.html#target-security-groups
data "aws_network_interface" "each_network_interface" {
  for_each = var.private_subnets

  filter {
    name = "description"
    /*
    Filter with nlb id in the description.
    Example of description: ELB net/nlb-jenkins-agents/c13704bf0d2c7995
    */
    values = ["*${split("/", aws_lb.nlb_agents.arn)[3]}*"]
  }

  filter {
    name   = "subnet-id"
    values = [each.key]
  }
}
