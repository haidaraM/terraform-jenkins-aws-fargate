####### NLB
resource "aws_lb" "nlb_agents" {
  name                             = "nlb-jenkins-agents"
  load_balancer_type               = "network"
  internal                         = true
  subnets                          = var.private_subnets
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
}


# Target group on the controller listening port for agents to communicate with it
resource "aws_lb_target_group" "nlb_agents_to_controller_http" {
  name        = "nlb-http-jenkins-agents"
  target_type = "ip"
  port        = var.controller_listening_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id


  health_check {
    path                = "/login"
    port                = var.controller_listening_port
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  stickiness {
    enabled = false # nlb target group don't support stickiness
    type    = "source_ip"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*
 Listener 80 for the NLB
*/
resource "aws_lb_listener" "agents_http_listener" {
  load_balancer_arn = aws_lb.nlb_agents.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_agents_to_controller_http.arn
  }
}

# Target group on the controller JNLP port for agents to communicate with it
resource "aws_lb_target_group" "nlb_agents_to_controller_jnlp" {
  name        = "nlb-jnlp-jenkins-agents"
  target_type = "ip"
  port        = var.controller_jnlp_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  # Fixme: looks like we can't put the health check on the jnlp port
  health_check {
    path                = "/login"
    port                = var.controller_listening_port
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  stickiness {
    enabled = false # nlb don't support stickiness
    type    = "source_ip"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "agents_jnlp_listener" {
  load_balancer_arn = aws_lb.nlb_agents.arn
  port              = var.controller_jnlp_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_agents_to_controller_jnlp.arn
  }
}

