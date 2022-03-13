resource "aws_alb" "alb_jenkins_controller" {
  name                       = "alb-jenkins-controller"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_security_group.id]
  subnets                    = var.public_subnets
  ip_address_type            = "ipv4"
  enable_deletion_protection = false
}

resource "aws_alb_target_group" "jenkins_controller_tg" {
  name        = "alb-http-jenkins-controller"
  port        = var.controller_listening_port
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  health_check {
    path                = "/login"
    timeout             = 10
    interval            = 45
    healthy_threshold   = 3
    unhealthy_threshold = 10
  }

  lifecycle {
    create_before_destroy = true
  }
}

# This listener is used when dont't use https with the ALB
resource "aws_lb_listener" "controller_http" {
  count             = var.route53_zone_name != "" ? 0 : 1
  load_balancer_arn = aws_alb.alb_jenkins_controller.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jenkins_controller_tg.arn
  }
}


resource "aws_lb_listener" "controller_http_redirect" {
  count             = var.route53_zone_name != "" ? 1 : 0
  load_balancer_arn = aws_alb.alb_jenkins_controller.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      host        = local.jenkins_host
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "controller_https" {
  count             = var.route53_zone_name != "" ? 1 : 0
  load_balancer_arn = aws_alb.alb_jenkins_controller.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.controller_certificate[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jenkins_controller_tg.arn
  }
}
