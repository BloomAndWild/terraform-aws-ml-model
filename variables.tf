variable "model_name" {
  type        = string
  description = "Name that uniquely identifies the ML model"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository for the model code"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment of the model (e.g. production, staging, development)"
}

variable "github_branch" {
  default     = "main"
  type        = string
  description = "GitHub branch that should trigger the CD Pipeline"
}

variable "cpu" {
  type        = string
  default     = "256"
  description = "CPU allocation for the ECS task"
}

variable "memory" {
  type        = string
  default     = "512"
  description = "Memory allocation for the ECS task"
}

variable "additional_iam_policy" {
  type        = string
  default     = ""
  description = "Additional IAM policy to attach to the execution role of the ECS task"
}

variable "codestar_connection_arn" {
  type        = string
  description = "AWS CodeStar Connection ARN to use to connect GitHub with the CD Pipeline"
}

variable "codebuild_vpc_id" {
  type        = string
  description = "VPC id where we want the CD Pipeline CodeBuild Project to run in"
}

variable "codebuild_security_group_ids" {
  type        = list(string)
  description = "Security Group IDs where we want the CD Pipeline CodeBuild Project to run in"
}

variable "codebuild_subnets" {
  type        = list(string)
  description = "Subnets where we want the CD Pipeline CodeBuild Project to run in"
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API key to use for the Firelens log driver"
  sensitive   = true
}

variable "parameter_store_kms_key" {
  type        = string
  description = "KMS key ID to use to decrypt SSM parameters at run time on the ECS task"
}