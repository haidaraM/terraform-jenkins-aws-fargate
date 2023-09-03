resource "aws_ecr_repository" "jenkins_agent" {
  name         = "jenkins-agent"
  force_delete = true
}

resource "aws_ecr_repository" "jenkins_controller" {
  name         = "jenkins-controller"
  force_delete = true
}