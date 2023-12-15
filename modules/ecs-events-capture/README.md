# ECS Events Capture

This module creates the resources required to capture the relevant ECS Task events in a CloudWatch Log Group. The events
are used to calculate the startup time of the ECS Tasks (the controller and the agents).

To calculate the startup time, a Python script is used to get and parse the events from CloudWatch:

```shell
cd src
pip3 install -r requirements.txt
export LOG_GROUP_NAME="" # The name of log group created by the module. See the Terraform output `log_group_name`
python3 analyze-ecs-events.py
```

Based on https://github.com/aws-samples/aws-fargate-seekable-oci-toolbox/blob/main/ecs-task-events/README.md + some
modifications.

## Usage

### The scripts

The scripts require installing the dependencies from `requirements.txt`.

- [restart-controller.py](src/restart-controller.py): Restarts the controller ECS Task.
    ```
    usage: restart-controller.py [-h] [--cluster-name CLUSTER_NAME] [--service-name SERVICE_NAME] [-i ITERATIONS]
    
    Restart service updates to trigger ECS events.
    
    options:
      -h, --help            show this help message and exit
      --cluster-name CLUSTER_NAME
                            ECS cluster name. Default: jenkins-cluster
      --service-name SERVICE_NAME
                            ECS service name. Default: jenkins-controller
      -i ITERATIONS, --iterations ITERATIONS
                            Number of updates. Default: 16
    ```
- [trigger-job.py](src/trigger-job.py) is a Python script that triggers a Jenkins job a certain number of times.
    ```
    usage: trigger-job.py [-h] [-i ITERATIONS] -u USER -p PASSWORD -s SERVER job_name
    
    Trigger a Jenkins job and wait for it to complete. Example: python3 trigger-job.py -s http://localhost:8080 -u admin -p admin -i 10 job-full-name
    
    positional arguments:
      job_name              The name of the job to trigger. The name of the job created by default by the module is 'example'.
    
    options:
      -h, --help            show this help message and exit
      -i ITERATIONS, --iterations ITERATIONS
                            The number of times to trigger the job. Default: 1
      -u USER, --user USER  The username to use to authenticate to Jenkins.
      -p PASSWORD, --password PASSWORD
                            The password to use to authenticate to Jenkins.
      -s SERVER, --server SERVER
                            The URL of the Jenkins server.
    ```

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