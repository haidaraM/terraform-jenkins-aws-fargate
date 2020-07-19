data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

################################### Master ECS execution role
resource "aws_iam_role" "master_ecs_execution_role" {
  name                  = "jenkins-master-ecs-execution"
  description           = "Role used by ECS to push Jenkins Master logs to Cloudwatch and access ECR."
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true
  tags                  = var.default_tags
}

resource "aws_iam_role_policy_attachment" "master_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.master_ecs_execution_role.name
}

################################### Master ECS task role
resource "aws_iam_role" "master_ecs_task_role" {
  name                  = "jenkins-master-ecs-task"
  description           = "Role used by the Jenkins Master to access AWS resources."
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true
  tags                  = var.default_tags
}

resource "aws_iam_policy" "master_ecs_task" {
  name        = "jenkins-master-ecs-task-role-policy"
  description = "Policy for Jenkins Master task role."
  policy      = data.aws_iam_policy_document.master_ecs_task.json
}

resource "aws_iam_role_policy_attachment" "master_ecs_task" {
  policy_arn = aws_iam_policy.master_ecs_task.arn
  role       = aws_iam_role.master_ecs_task_role.name
}

# see jenkins ecs plugin documentation: https://plugins.jenkins.io/scalable-amazon-ecs/
data "aws_iam_policy_document" "master_ecs_task" {

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

################################### Agents execution Role
resource "aws_iam_role" "agents_ecs_execution_role" {
  name                  = "jenkins-agents-ecs-execution"
  description           = "Role used by ECS to push Jenkins agents logs to Cloudwatch and access ECR."
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true
  tags                  = var.default_tags
}

resource "aws_iam_role_policy_attachment" "agents_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.agents_ecs_execution_role.name
}


################################### Agents task Role
resource "aws_iam_role" "agents_ecs_task_role" {
  name                  = "jenkins-agents-ecs-task"
  description           = "Example of role attached to the agents."
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true
  tags                  = var.default_tags
}