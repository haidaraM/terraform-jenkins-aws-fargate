# Containerized SOCI Index Builder

Builds a SOCI index in a container. Useful when testing locally. Otherwise, use the more scalable
[SOCI Lambda index builder.](https://github.com/aws-ia/cfn-ecr-aws-soci-index-builder)

Based on https://github.com/aws-samples/aws-fargate-seekable-oci-toolbox/blob/main/containerized-index-builder/README.md

## Using this container image

First build the container image

```bash
docker build --tag sociindexbuilder:latest .
```

And then run the container image, passing in the workload image as the
command (hello-world in this example).

> The example below is fetching and generating an index for a container image
> stored in Amazon ECS (Hence the AWS_REGION environment variable and the
> `--volume` mount of the local AWS credentials).

```bash
docker run \
	--rm \
	--privileged \
	--env AWS_REGION=us-east-1 \
	--mount type=tmpfs,destination=/var/lib/containerd \
	--mount type=tmpfs,destination=/var/lib/soci-snapshotter-grpc \
	--volume ${HOME}/.aws:/root/.aws \
	sociindexbuilder:latest \
	979933559541.dkr.ecr.us-east-1.amazonaws.com/jenkins-agent:latest-alpine
```

### Minimum Layer Size

There is an initial overhead when lazy loading a container image layer as the
SOCI artifacts need to be downloaded and the FUSE file system needs to be
configured. Therefore, for small container image layer it may actually be quicker
to just do a pull the layer whole, rather then lazily loading it.

By default, when running `soci create` if the container image layer is less then
10MB we will not create an index for it, therefore it will not be lazy loaded.
This value is adjustable, so you can pass in `--env MIN_LAYER_SIZE` to the
container image and set a new MB limit for the `soci create` command. So to
index all container image layers 5 MB or pass in `--env MIN_LAYER_SIZE=5`.

### Architecture

This index builder tool is not multi architecture aware. It will only create a
SOCI Index for a single architecture of a container image at a time. By default
the index builder tool expects to pull and create an Index for an x86 container
image. That value can be overridden with the `--env IMAGE_ARCH` variable. For
example to index an arm64 container image pass in `--env
IMAGE_ARCH=linux/arm64`.