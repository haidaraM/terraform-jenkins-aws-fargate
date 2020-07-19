# Docker images
The folder contains the docker images used in Terraform: the Jenkins Master one and the agent one. Both images
are based on the official images with some customization. 

## Jenkins Master: Dockerfile
In this image, we install some required plugins. See [plugins](./plugins.txt). 

The entrypoint is also override to fetch the configuration from S3 if the variable `JENKINS_CONF_S3_URL` if defined. 
This configuration will be read the Jenkins configuration as code plugin. 

To build the image:
```shell script
docker build  -f Dockerfile .
```

You can pull it from docker hub: `docker pull elmhaidara/jenkins-aws-fargate:latest`.

## Jenkins agents: Dockerfile.agent
Image for Jenkins agents. We install some packages as example. Not that all Jenkins agents images must 
derived from `jenkins/inbound-agent`.

To build the image:
```shell script
docker build  -f Dockerfile.agent .
```

You can pull it from docker hub: `docker pull elmhaidara/jenkins-alpine-agent-aws:latest`.