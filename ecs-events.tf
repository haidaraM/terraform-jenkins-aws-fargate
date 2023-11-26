module "ecs_events" {
  count       = var.soci.enabled ? 1 : 0
  source      = "./modules/ecs-events-capture"
  cluster_arn = aws_ecs_cluster.cluster.arn
  name_prefix = "mohamed-test-jenkins"
}
