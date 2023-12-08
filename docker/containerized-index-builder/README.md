# Containerized SOCI Index Builder

Builds a SOCI index in a container. Useful when testing locally, and we don't want to deploy a lambda function.
Otherwise, use the more scalable [SOCI Lambda index builder.](https://github.com/aws-ia/cfn-ecr-aws-soci-index-builder)

Based on https://github.com/aws-samples/aws-fargate-seekable-oci-toolbox/blob/main/containerized-index-builder/README.md

## Using this container image

First build the container image:

```bash
docker build --tag soci-index-builder .
```

Or pull it
from [Docker Hub](https://hub.docker.com/repository/docker/elmhaidara/soci-index-builder/general): `docker pull elmhaidara/soci-index-builder:21ec5445ea5e0908861e60e92cbdcd70d3251c93`

And then run the container image, passing in the workload image as the
command (hello-world in this example).

> The example below is fetching, generating and pushing an index for a container image
> stored in Amazon ECR (979933559541.dkr.ecr.us-east-1.amazonaws.com/jenkins-agent:latest-alpine). 
> Hence, the AWS_REGION environment variable and the `--volume` mount of the local AWS credentials.
> After this command, you will have an index for the image in ECR.

```bash
docker run \
	--rm \
	--privileged \
	--env AWS_REGION=us-east-1 \
	--mount type=tmpfs,destination=/var/lib/containerd \
	--mount type=tmpfs,destination=/var/lib/soci-snapshotter-grpc \
	--platform linux/amd64 \
	--volume ${HOME}/.aws:/root/.aws \
	elmhaidara/soci-index-builder \
	xxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/jenkins-agent:latest-alpine
```

If you are using AWS profiles, you can pass them as environment variables to the
container: `--env AWS_PROFILE=my-profile`.

For a more in depth understanding of the various commands and options, refer
to [this.](https://aws.amazon.com/fr/blogs/aws/aws-fargate-enables-faster-container-startup-using-seekable-oci/)

### Architecture

This index builder tool is not multi-architecture-aware. It will only create a SOCI Index for a single architecture of a
container image at a time. By default, the index builder tool expects to pull and create an Index for an x86 container
image. That value can be overridden with the `--env IMAGE_ARCH` variable. For example, to index an arm64 container image
pass in `--env IMAGE_ARCH=linux/arm64`.
