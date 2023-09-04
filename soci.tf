locals {
  soci_index_builder_image = "sociindexbuilder:latest"
  soci_index_builder_dir   = "${path.module}/docker/containerized-index-builder"
  soci_images_to_push_ecr = var.soci.enabled ? {
    (var.agent_docker_image) : "${aws_ecr_repository.jenkins_agent[0].repository_url}:${local.agent_docker_image_version}"
    (var.controller_docker_image) : "${aws_ecr_repository.jenkins_controller[0].repository_url}:${local.controller_docker_image_version}"
  } : {}
  soci_docker_run_env_vars = merge({ AWS_REGION = var.aws_region, IMAGE_ARCH = "linux/amd64" }, var.soci.env_vars)
}

resource "aws_ecr_repository" "jenkins_agent" {
  count                = var.soci.enabled ? 1 : 0
  name                 = "jenkins-agent"
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
 This is just a convenient way to build and push the images to ECR. Usually, this is one outside of Terraform.
 If you are having trouble building image here, feel free to do it outside of Terraform.
 # TODO: push this image to DockerHub
*/
resource "terraform_data" "build_soci_index_builder" {
  count = var.soci.enabled ? 1 : 0
  triggers_replace = [
    filebase64sha256("${local.soci_index_builder_dir}/Dockerfile"),
    filebase64sha256("${local.soci_index_builder_dir}/script.sh"),
  ]
  provisioner "local-exec" {
    working_dir = local.soci_index_builder_dir
    command     = "docker build --tag ${local.soci_index_builder_image} ."
  }
}

resource "terraform_data" "build_agent_soci_indexes" {
  for_each = var.soci.enabled ? local.soci_images_to_push_ecr : {}
  triggers_replace = [
    each.key,
    each.value,
    local.soci_docker_run_env_vars
  ]

  provisioner "local-exec" {
    # Pull and push the default image to ECR WITHOUT the index
    command = "docker pull ${each.key} && docker tag ${each.key} ${each.value} && docker push ${each.value}"
  }

  provisioner "local-exec" {
    # Push the SOCI index to ECR
    environment = local.soci_docker_run_env_vars
    working_dir = local.soci_index_builder_dir
    command     = <<CMD
    docker run --rm --privileged --env AWS_REGION --env IMAGE_ARCH \
        ${join(" ", formatlist("--env %s", keys(local.soci_docker_run_env_vars)))} \
        --mount type=tmpfs,destination=/var/lib/containerd \
        --mount type=tmpfs,destination=/var/lib/soci-snapshotter-grpc \
        --volume $${HOME}/.aws:/root/.aws \
        ${local.soci_index_builder_image} \
        ${each.value}
    CMD
  }

  lifecycle {
    replace_triggered_by = [terraform_data.build_soci_index_builder]
  }
}
