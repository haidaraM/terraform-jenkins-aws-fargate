resource "aws_security_group" "jenkins_controller_ecs_service" {
  name        = "sgr-jenkins-controller-ecs-service"
  description = "Jenkins Controller ECS service security group."
  vpc_id      = var.vpc_id
  tags        = { "Name" : "sgr-jenkins-controller-service" }
}

resource "aws_security_group" "alb_security_group" {
  name        = "sgr-jenkins-controller-alb"
  description = "Jenkins Controller ALB security group."
  vpc_id      = var.vpc_id
  tags        = { "Name" : "sgr-jenkins-controller-alb" }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb_security_group.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = var.allowed_ip_addresses
}

resource "aws_security_group_rule" "alb_ingress_https" {
  count             = var.route53_zone_name != "" ? 1 : 0
  security_group_id = aws_security_group.alb_security_group.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = var.allowed_ip_addresses
}

resource "aws_security_group_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb_security_group.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "jenkins_controller_ingress_alb" {
  security_group_id        = aws_security_group.jenkins_controller_ecs_service.id
  from_port                = var.controller_listening_port
  to_port                  = var.controller_listening_port
  protocol                 = "tcp"
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_security_group.id
  description              = "From ALB to Jenkins Controller listening port."
}

resource "aws_security_group_rule" "allow_agents_to_jks_jnlp_port" {
  for_each          = var.private_subnets
  security_group_id = aws_security_group.jenkins_controller_ecs_service.id
  from_port         = var.controller_jnlp_port
  to_port           = var.controller_jnlp_port
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["${data.aws_network_interface.each_network_interface[each.key].private_ip}/32"]
  description       = "From the NLB to the Jenkins Controller via JNLP and ENI ${data.aws_network_interface.each_network_interface[each.key].id}."
}

# When using a private nlb we need to have this rule for nlb health check to work.
resource "aws_security_group_rule" "from_private_nlb_network_interfaces" {
  for_each          = var.private_subnets
  security_group_id = aws_security_group.jenkins_controller_ecs_service.id
  from_port         = var.controller_listening_port
  to_port           = var.controller_listening_port
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["${data.aws_network_interface.each_network_interface[each.key].private_ip}/32"]
  description       = "From the NLB to the Jenkins Controller via HTTP and ENI ${data.aws_network_interface.each_network_interface[each.key].id}. Required for health check."
}

resource "aws_security_group_rule" "controller_egress_all" {
  security_group_id = aws_security_group.jenkins_controller_ecs_service.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "jenkins_agents" {
  name        = "sgr-jenkins-agents"
  description = "Security group attached to Jenkins agents running in Fargate."
  vpc_id      = var.vpc_id
  tags        = { "Name" : "sgr-jenkins-agents" }
}

resource "aws_security_group_rule" "jenkins_agent_egress" {
  security_group_id = aws_security_group.jenkins_agents.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

### EFS
resource "aws_security_group" "efs" {
  name        = "sgr-jenkins-controller-efs"
  description = "Jenkins Controller EFS security group."
  vpc_id      = var.vpc_id
  tags        = { "Name" : "sgr-jenkins-controller-efs" }
}

resource "aws_security_group_rule" "allow_jenkins_to_efs" {
  security_group_id        = aws_security_group.efs.id
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  type                     = "ingress"
  description              = "Jenkins Controller access to EFS."
  source_security_group_id = aws_security_group.jenkins_controller_ecs_service.id
}
