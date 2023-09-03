module "ecs_events" {
  source      = "./modules/ecs-events-capture"
  cluster_arn = aws_ecs_cluster.cluster.arn
  name_prefix = "mohamed-test-jenkins"
}
