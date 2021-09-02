locals {
  default_tags = {
    "service" = var.model_name
    "name"    = var.model_name
    "env"     = var.environment
  }

  aws_region_name            = data.aws_region.current.name
  aws_account_id             = data.aws_caller_identity.current.account_id
  resource_prefix            = "${var.environment}-${var.model_name}"
  ecr_repository_arn         = "arn:aws:ecr:${local.aws_region_name}:${local.aws_account_id}:repository/${var.model_name}/app"
  ecr_repository_url         = "${local.aws_account_id}.dkr.ecr.${local.aws_region_name}.amazonaws.com/${var.model_name}/app"
  buildspec_file             = "codebuild/build.yml"
  github_repo_owner          = "BloomAndWild"
  ssm_path_arn               = "arn:aws:ssm:${local.aws_region_name}:${local.aws_account_id}:parameter/${var.environment}/${var.model_name}"
  application_s3_bucket_arn  = "arn:aws:s3:::${local.resource_prefix}"
  application_s3_bucket      = local.resource_prefix
  log_group_arn              = "arn:aws:logs:${local.aws_region_name}:${local.aws_account_id}:log-group:/${local.resource_prefix}"
  fluentbit_ecr_image_url    = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
  additional_iam_policy_name = "${local.resource_prefix}-additional-ecs-task-policy"
}
