# v2.0.1 (unreleased)

- fix: Do not use S3 ACL anymore. See this
  announcement https://aws.amazon.com/about-aws/whats-new/2022/12/amazon-s3-automatically-enable-block-public-access-disable-access-control-lists-buckets-april-2023/

# v2.0.0

## What's Changed

* feat: Update AWS provider, Jenkins, plugins... by @haidaraM
  in https://github.com/haidaraM/terraform-jenkins-aws-fargate/pull/2
    - Terraform `>= 1` is required
    - Make the project compatible with AWS Provider V4. Define tags at the provider level
    - Add pre-commit for validation, lint, docs generation and format
    - Rename all `master` references by `controller` in the Terraform Code
    - Fix typos
    - Pull all data sources in single file `data.tf`
    - Add new input `allowed_ip_addresses` to restrict access to the controller ALB

## New Contributors

* @haidaraM made their first contribution in https://github.com/haidaraM/terraform-jenkins-aws-fargate/pull/2

**Full Changelog**: https://github.com/haidaraM/terraform-jenkins-aws-fargate/compare/v1.0.1...v2.0.0

# v1.0.1

- fix: Add support for AWS provider V3
- fix: Use variable efs_provisioned_throughput_in_mibps

# v1.0.0

Initial version

