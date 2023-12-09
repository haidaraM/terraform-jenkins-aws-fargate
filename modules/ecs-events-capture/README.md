# ECS Events Capture

This module creates the resources required to capture the relevant ECS Task events in a CloudWatch Log Group. The events
are used to calculate the startup time of the ECS Tasks (the controller and the agents).

To calculate the startup time, a Python script is used to get and parse the events from CloudWatch:

```shell
cd src
pip3 install -r requirements.txt
export LOG_GROUP_NAME="" # The name of log group created by the module. See the Terraform output `log_group_name`
python3 main.py
```

Based on https://github.com/aws-samples/aws-fargate-seekable-oci-toolbox/blob/main/ecs-task-events/README.md + some
modifications.

## Usage

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.task_state_change](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.task_state_change](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.task_state_change](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_arn.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | The ARNs of the ECS clusters to listen to for events. | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | The name of the CloudWatch Log Group containing the ECS events |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->