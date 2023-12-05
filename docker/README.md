# Docker images

The folder contains the docker images used in Terraform: the Jenkins Controller and the agent. Both images are based on
the official images with some customization.

## Jenkins Controller: Dockerfile

In this image, we install some required plugins. See the [plugins](./plugins.txt) file.

[Link to the official image.](https://github.com/jenkinsci/docker/blob/master/README.md)

The entrypoint is also overridden to fetch the configuration from S3 if the variable `JENKINS_CONF_S3_URL` is defined.
This configuration will be read by the Jenkins configuration as code plugin.

To build the image:

```shell
docker build -f Dockerfile -t elmhaidara/jenkins-aws-fargate .
```

You can pull it from Docker Hub: `docker pull elmhaidara/jenkins-aws-fargate:2.420`.

## Jenkins agents: Dockerfile.agent

Image for Jenkins agents. We install some packages as example. Note that all Jenkins agents images must derive
from `jenkins/inbound-agent`.

To build the image:

```shell
docker build  -f Dockerfile.agent -t elmhaidara/jenkins-alpine-agent-aws .
```

You can pull it from Docker Hub: `docker pull elmhaidara/jenkins-alpine-agent-aws:3192.v713e3b_039fb_e-4-alpine-jdk17`.

## Containerized Index Builder

To build a SOCI index inside a container, you can use the [containerized-index-builder](./containerized-index-builder/)
tool.

The image is available on Docker Hub as `elmhaidara/soci-index-builder:21ec5445ea5e0908861e60e92cbdcd70d3251c93`.
