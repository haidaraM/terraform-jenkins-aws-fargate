locals {
  soci_images_to_push_ecr = var.soci.enabled ? {
    (var.agent_docker_image) : "${aws_ecr_repository.jenkins_agent[0].repository_url}:${local.agent_docker_image_version}"
    (var.controller_docker_image) : "${aws_ecr_repository.jenkins_controller[0].repository_url}:${local.controller_docker_image_version}"
  } : {}
  docker_cmds_env_vars = var.soci.enabled ? merge({ AWS_REGION = var.aws_region, IMAGE_ARCH = "linux/amd64" }, var.soci.env_vars) : {}
}

resource "aws_ecr_repository" "jenkins_agent" {
  count                = var.soci.enabled ? 1 : 0
  name                 = "jenkins-alpine-agent-aws"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "jenkins_controller" {
  count                = var.soci.enabled ? 1 : 0
  name                 = "jenkins-controller"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
}

/**
 If you are having the error "denied: Your authorization token has expired. Reauthenticate and try again." when running terraform apply,
 taint this resource and run terraform apply again: terraform taint 'terraform_data.ecr_login[0]'.
 The reason for this is that the ECR login token is valid for 12 hours.
*/
resource "terraform_data" "ecr_login" {
  count = var.soci.enabled ? 1 : 0
  provisioner "local-exec" {
    environment = local.docker_cmds_env_vars
    command     = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.caller.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  }
}


/**
 This is just a convenient way to build and push the images to ECR. Usually, this is done outside of Terraform.
 If you are having trouble building image here, feel free to do it outside of Terraform and update the images in the variables.
*/
resource "terraform_data" "build_and_push_soci_indexes" {
  for_each = local.soci_images_to_push_ecr
  triggers_replace = [
    each.key,
    each.value,
    local.docker_cmds_env_vars,
    var.soci.index_builder_image,
  ]

  provisioner "local-exec" {
    # Pull and push the default image to ECR WITHOUT the index
    environment = local.docker_cmds_env_vars
    command     = "docker pull ${each.key} && docker tag ${each.key} ${each.value} && docker push ${each.value}"
  }

  provisioner "local-exec" {
    # Build and Push the SOCI index to ECR
    environment = local.docker_cmds_env_vars
    command     = <<CMD
    docker run --rm --privileged \
        ${join(" ", formatlist("--env %s", keys(local.docker_cmds_env_vars)))} \
        --mount type=tmpfs,destination=/var/lib/containerd \
        --platform linux/amd64 \
        --mount type=tmpfs,destination=/var/lib/soci-snapshotter-grpc \
        --volume $${HOME}/.aws:/root/.aws \
        ${var.soci.index_builder_image} \
        ${each.value}
    CMD
  }

  depends_on = [
    terraform_data.ecr_login
  ]
}

/**
  This is a small hack to trigger the controller task definition replacement when the controller image/index is updated.
*/
resource "terraform_data" "trigger_controller_task_def_replacement" {
  input = var.soci.enabled ? terraform_data.build_and_push_soci_indexes[var.controller_docker_image].id : null
}
