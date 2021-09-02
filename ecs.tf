# ECS task definition

data "aws_ecs_task_definition" "primary" {
  task_definition = local.resource_prefix

  # https://github.com/hashicorp/terraform/issues/16380
  depends_on = [aws_ecs_task_definition.primary]
}

resource "aws_ecs_task_definition" "primary" {
  tags   = { "name" = local.resource_prefix }
  family = local.resource_prefix

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory

  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  # Containers
  container_definitions = <<DEFINITION
[
  {
    "ulimits": [
      {
        "name": "nofile",
        "softLimit": 1048576,
        "hardLimit": 1048576
      }
    ],
    "logConfiguration": {
      "logDriver": "awsfirelens",
      "options": {
          "apiKey": "${var.datadog_api_key}",
          "provider": "ecs",
          "dd_service": "${var.model_name}",
          "dd_source": "python",
          "dd_tags": "env:${var.environment}",
          "Name": "datadog"
      }
    },
    "essential": true,
    "dockerLabels": {
        "com.datadoghq.tags.env": "${var.environment}",
        "com.datadoghq.tags.service": "${var.model_name}"
    },
    "image": "${local.ecr_repository_url}:${var.environment}_latest",
    "name": "app",
    "environment": [
      {"name": "ENVIRONMENT", "value": "${var.environment}"}
    ],
    "mountPoints": [],
    "portMappings": [],
    "volumesFrom": [],
    "cpu": 0,
    "user": "0"
  },
  {
      "image": "${local.fluentbit_ecr_image_url}",
      "environment": [],
      "mountPoints": [],
      "portMappings": [],
      "volumesFrom": [],
      "cpu": 0,
      "user": "0",
      "firelensConfiguration": {
          "type": "fluentbit",
          "options": {
              "config-file-type": "file",
              "enable-ecs-log-metadata": "true",
              "config-file-value": "/fluent-bit/configs/parse-json.conf"
          }
      },
      "essential": true,
      "name": "log_router"
  },
  {
      "logConfiguration": {
        "logDriver": "awsfirelens",
        "options": {
            "apiKey": "${var.datadog_api_key}",
            "provider": "ecs",
            "dd_service": "datadog-agent",
            "dd_tags": "env:${var.environment}",
            "Name": "datadog"
        }
      },
      "portMappings": [],
      "cpu": 0,
      "environment": [
        {
          "name": "DD_API_KEY",
          "value": "${var.datadog_api_key}"
        },
        {
          "name": "DD_APM_ENABLED",
          "value": "true"
        },
        {
          "name": "DD_ENV",
          "value": "${var.environment}"
        },
        {
          "name": "DD_SERVICE",
          "value": "datadog-agent"
        },
        {
          "name": "ECS_FARGATE",
          "value": "true"
        }
      ],
      "mountPoints": [],
      "volumesFrom": [],
      "image": "datadog/agent:latest",
      "essential": true,
      "name": "datadog-agent"
    }
]
DEFINITION
}

# IAM roles and policies for ECS

resource "aws_iam_role" "ecs_task_role" {
  tags = { "name" = "${local.resource_prefix}-task-role" }
  name = "${local.resource_prefix}-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "ecs_task_policy" {
  tags        = { "name" = "${local.resource_prefix}-task-policy" }
  name        = "${local.resource_prefix}-task-policy"
  description = "${local.resource_prefix} - ECS Task Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": [
                "arn:aws:ssm:${local.aws_region_name}:${local.aws_account_id}:*"
            ]
        },
        {
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:kms:*:${local.aws_account_id}:key/${var.parameter_store_kms_key}"
            ],
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:*"
            ],
            "Resource": [
                "arn:aws:dynamodb:${local.aws_region_name}:${local.aws_account_id}:table/${local.resource_prefix}-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": [
                "${local.ssm_path_arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectTagging",
                "s3:DeleteObject",
                "s3:ListObjectsV2",
                "s3:ListBucket"
            ],
            "Resource": "${local.application_s3_bucket_arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "additional_ecs_task_policy" {
  count       = var.additional_iam_policy == "" ? 0 : 1
  name        = "${local.resource_prefix}-additional-task-policy"
  description = "${local.resource_prefix} - Additional ECS Task Policy"
  policy      = var.additional_iam_policy
}

resource "aws_iam_role" "ecs_execution_role" {
  tags = { "name" = "${local.resource_prefix}-execution-role" }
  name = "${local.resource_prefix}-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_execution_policy" {
  tags        = { "name" = "${local.resource_prefix}-execution-policy" }
  name        = "${local.resource_prefix}-execution-policy"
  description = "${local.resource_prefix} - ECS Execution Policy"

  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                "ecr:GetAuthorizationToken"
              ],
              "Resource": [
                "*"
              ]
          },
          {
              "Effect": "Allow",
              "Action": [
                  "ecr:BatchCheckLayerAvailability",
                  "ecr:GetDownloadUrlForLayer",
                  "ecr:BatchGetImage"
              ],
              "Resource": [
                "${local.ecr_repository_arn}"
              ]
          },
          {
              "Effect": "Allow",
              "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ],
              "Resource": [
                "${local.log_group_arn}:*"
              ]
          },
          {
              "Effect": "Allow",
              "Action": [
                  "ssm:GetParametersByPath",
                  "ssm:GetParameters",
                  "ssm:GetParameter"
              ],
              "Resource": [
                  "${local.ssm_path_arn}/*"
              ]
          }
      ]
  }
EOF
}

resource "aws_iam_role_policy_attachment" "execution_role_allow_ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_role_allow_ecs_task" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_role_allow_additional_ecs_task" {
  count      = var.additional_iam_policy == "" ? 0 : 1
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.additional_ecs_task_policy[count.index].arn
}
