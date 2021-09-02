# terraform-aws-ml-model

This is an example module to accompany the Code & Wild blog post [Building a Machine Learning Orchestration Platform: Part 1](https://www.bloomandwild.com).

As mentioned on the blog post, this module makes a few assumptions when it comes to naming conventions and to some of the monitoring tools used which are external to AWS, like Datadog for managing your application logs.

The module will link a GitHub repository to a CodePipeline pipeline which will check out the code and run a CodeBuild project that will execute the `codebuild/buildspec.yml` file. An example GitHub repository that can be combined with this module can be found in our public GitHub profile, under the name [opensource-ml-model-template](https://github.com/BloomAndWild/opensource-ml-model-template). That repository will allow the pipeline to build and push a Docker image to ECR which then can be run via ECS Fargate.

The module also creates an ECR repository, an ECS task definition and some other supporting infrastructure.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_codebuild_project.build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_task_definition.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.additional_ecs_task_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.codebuild_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.codepipeline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_task_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.codebuild_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_policy_attachment.codepipeline_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.execution_role_allow_ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_role_allow_additional_ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_role_allow_ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecs_task_definition.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_iam_policy"></a> [additional\_iam\_policy](#input\_additional\_iam\_policy) | Additional IAM policy to attach to the execution role of the ECS task | `string` | `""` | no |
| <a name="input_codebuild_security_group_ids"></a> [codebuild\_security\_group\_ids](#input\_codebuild\_security\_group\_ids) | Security Group IDs where we want the CD Pipeline CodeBuild Project to run in | `list(string)` | n/a | yes |
| <a name="input_codebuild_subnets"></a> [codebuild\_subnets](#input\_codebuild\_subnets) | Subnets where we want the CD Pipeline CodeBuild Project to run in | `list(string)` | n/a | yes |
| <a name="input_codebuild_vpc_id"></a> [codebuild\_vpc\_id](#input\_codebuild\_vpc\_id) | VPC id where we want the CD Pipeline CodeBuild Project to run in | `string` | n/a | yes |
| <a name="input_codestar_connection_arn"></a> [codestar\_connection\_arn](#input\_codestar\_connection\_arn) | AWS CodeStar Connection ARN to use to connect GitHub with the CD Pipeline | `string` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU allocation for the ECS task | `string` | `"256"` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key to use for the Firelens log driver | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment of the model (e.g. production, staging, development) | `string` | `"production"` | no |
| <a name="input_github_branch"></a> [github\_branch](#input\_github\_branch) | GitHub branch that should trigger the CD Pipeline | `string` | `"main"` | no |
| <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository) | GitHub repository for the model code | `string` | n/a | yes |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory allocation for the ECS task | `string` | `"512"` | no |
| <a name="input_model_name"></a> [model\_name](#input\_model\_name) | Name that uniquely identifies the ML model | `string` | n/a | yes |
| <a name="input_parameter_store_kms_key"></a> [parameter\_store\_kms\_key](#input\_parameter\_store\_kms\_key) | KMS key ID to use to decrypt SSM parameters at run time on the ECS task | `string` | n/a | yes |

## Outputs

No outputs.

## Example usage

Replace values as required.

```hcl
module "ml_model" {
  source = "github.com/BloomAndWild/terraform-aws-ml-model"

  model_name        = "example-model"
  github_repository = "BloomAndWild/opensource-ml-model-template"
  codestar_connection_arn = "arn:aws:codestar-connections:eu-west-1:XXXXXXXXXXXX:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  codebuild_vpc_id = "vpc-xxxxxxx"
  codebuild_security_group_ids = ["sg-xxxxxxx"]
  codebuild_subnets = ["subnet-xxxxxxxxxxxx", "subnet-xxxxxxxxxxxx"]
  datadog_api_key = "xxxxxxxxxxxxxxxxxxxxxx"
  parameter_store_kms_key = "xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

```