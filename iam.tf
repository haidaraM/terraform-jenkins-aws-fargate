################################### Controller ECS execution role
resource "aws_iam_role" "controller_ecs_execution_role" {
  name                  = "jenkins-controller-ecs-execution"
  description           = "Role used by ECS to push Jenkins Controller logs to Cloudwatch and access ECR."
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "controller_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.controller_ecs_execution_role.name
}

################################### Controller ECS task role
resource "aws_iam_role" "controller_ecs_task_role" {
  name                  = "jenkins-controller-ecs-task"
  description           = "Role used by the Jenkins Controller to access AWS resources."
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true
}

resource "aws_iam_policy" "controller_ecs_task" {
  name        = "jenkins-controller-ecs-task-role-policy"
  description = "Policy for Jenkins Controller task role."
  policy      = data.aws_iam_policy_document.controller_ecs_task.json
}

resource "aws_iam_role_policy_attachment" "controller_ecs_task" {
  policy_arn = aws_iam_policy.controller_ecs_task.arn
  role       = aws_iam_role.controller_ecs_task_role.name
}

################################### Agents execution Role
resource "aws_iam_role" "agents_ecs_execution_role" {
  name                  = "jenkins-agents-ecs-execution"
  description           = "Role used by ECS to push Jenkins agents logs to Cloudwatch and access ECR."
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true
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
}