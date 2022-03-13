#################### REQUIRED parameters
variable "private_subnets" {
  description = "Private subnets to deploy Jenkins and the internal NLB"
  type        = set(string)
}

variable "public_subnets" {
  description = "Public subnets to deploy the load balancer"
  type        = set(string)
}

variable "vpc_id" {
  description = "The VPC id"
  type        = string
}

#################### General variables
variable "aws_region" {
  description = "The AWS region in which deploy the resources"
  type        = string
  default     = "eu-west-1"
}

variable "route53_zone_name" {
  description = "A Route53 zone name to use to create a DNS record for the Jenkins Controller. Required for HTTPs."
  type        = string
  default     = ""
}

variable "route53_subdomain" {
  description = "The subdomain to use for Jenkins Controller. Used when var.route53_zone_name is not empty"
  type        = string
  default     = "jenkins"
}

variable "fargate_platform_version" {
  description = "Fargate platform version to use. Must be >= 1.4.0 to be able to use Fargate"
  type        = string
  default     = "1.4.0"
}

variable "default_tags" {
  description = "Default tags to apply to the resources"
  type        = map(string)
  default = {
    Application = "Jenkins"
    Environment = "test"
    Terraform   = "True"
  }
}

#################### Jenkins variables
variable "controller_cpu_memory" {
  description = "CPU and memory for Jenkins controller. Note that all combinations are not supported with Fargate."
  type = object({
    memory = number
    cpu    = number
  })
  default = {
    memory = 2048
    cpu    = 1024
  }
}

variable "agents_cpu_memory" {
  description = "CPU and memory for the agent example. Note that all combinations are not supported with Fargate."
  type = object({
    memory = number
    cpu    = number
  })
  default = {
    memory = 2048
    cpu    = 1024
  }
}

variable "controller_deployment_percentages" {
  description = "The Min and Max percentages of Controller instance to keep when updating the service. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/update-service.html"
  type = object({
    min = number
    max = number
  })
  default = {
    min = 0
    max = 100
  }
}

variable "controller_log_retention_days" {
  description = "Retention days for Controller log group"
  type        = number
  default     = 14
}

variable "agents_log_retention_days" {
  description = "Retention days for Agents log group"
  type        = number
  default     = 5
}

variable "controller_docker_image" {
  type        = string
  description = "Jenkins Controller docker image to use"
  default     = "elmhaidara/jenkins-aws-fargate:2.338"
}

variable "agent_docker_image" {
  type        = string
  description = "Docker image to use for the example agent. See: https://hub.docker.com/r/jenkins/inbound-agent/"
  default     = "elmhaidara/jenkins-alpine-agent-aws:latest-alpine"
}

variable "controller_listening_port" {
  type        = number
  default     = 8080
  description = "Jenkins container listening port"
}

variable "controller_jnlp_port" {
  type        = number
  default     = 50000
  description = "JNLP port used by Jenkins agent to communicate with the controller"
}

variable "controller_java_opts" {
  type        = string
  description = "JENKINS_OPTS to pass to the controller"
  default     = ""
}

variable "controller_num_executors" {
  type        = number
  description = "Set this to a number > 0 to be able to build on controller (NOT RECOMMENDED)"
  default     = 0
}

variable "controller_docker_user_uid_gid" {
  type        = number
  description = "Jenkins User/Group ID inside the container. One should consider using access point."
  default     = 0 # root
}

variable "efs_performance_mode" {
  type        = string
  description = "EFS performance mode. Valid values: generalPurpose or maxIO"
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  type        = string
  description = "Throughput mode for the file system. Valid values: bursting, provisioned. When using provisioned, also set provisioned_throughput_in_mibps"
  default     = "bursting"
}

variable "efs_provisioned_throughput_in_mibps" {
  type        = number
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned."
  default     = null
}

variable "efs_burst_credit_balance_threshold" {
  type        = number
  description = "Threshold below which the metric BurstCreditBalance associated alarm will be triggered. Expressed in bytes"
  default     = 1154487209164 # half of the default credits
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses to access the controller from the ALB"
  type        = set(string)
  default     = ["0.0.0.0/0"]
}