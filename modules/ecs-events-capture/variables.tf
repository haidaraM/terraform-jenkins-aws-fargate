variable "cluster_arn" {
  description = "The ARNs of the ECS clusters to listen to for events. "
  type        = string

  validation {
    condition     = length(var.cluster_arn) > 0
    error_message = "The cluster ARN must not be empty"
  }
}
