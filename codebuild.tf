# CodeBuild project that builds and pushes the application Docker image

resource "aws_codebuild_project" "build" {
  tags          = { "name" = "${local.resource_prefix}-build" }
  name          = "${local.resource_prefix}-build"
  build_timeout = 30
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:4.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

    environment_variable {
      name  = "REPOSITORY_URI"
      value = local.ecr_repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = local.buildspec_file
  }

  vpc_config {
    vpc_id             = var.codebuild_vpc_id
    security_group_ids = var.codebuild_security_group_ids
    subnets            = var.codebuild_subnets
  }
}

# IAM roles and policies for the CodeBuild project

resource "aws_iam_role" "codebuild_role" {
  tags = { "name" = "${local.resource_prefix}-codebuild-role" }
  name = "${local.resource_prefix}-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "codebuild_policy" {
  tags        = { "name" = "${local.resource_prefix}-codebuild-policy" }
  name        = "${local.resource_prefix}-codebuild-policy"
  description = "${local.resource_prefix} - CodeBuild Policy"
  path        = "/service-role/"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${local.aws_region_name}:${local.aws_account_id}:log-group:/aws/codebuild/${local.resource_prefix}-build:log-stream:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs"
      ],
      "Resource": [
        "*"
      ]
    },
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
        "*"
      ],
      "Resource": [
        "${local.ecr_repository_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.pipeline.arn}",
        "${aws_s3_bucket.pipeline.arn}/*"
      ],
      "Action": [
        "s3:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": [
        "${local.ssm_path_arn}/build/*"
      ]
    }
  ]
}
POLICY

}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "${local.resource_prefix}-codebuild-policy-attachment"
  policy_arn = aws_iam_policy.codebuild_policy.arn
  roles      = [aws_iam_role.codebuild_role.id]
}
