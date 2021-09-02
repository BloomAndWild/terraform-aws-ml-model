# AWS CodePipeline

resource "aws_codepipeline" "this" {
  tags     = { "name" = local.resource_prefix }
  name     = local.resource_prefix
  role_arn = aws_iam_role.codepipeline_role.arn

  depends_on = [
    aws_iam_role.codepipeline_role,
    aws_iam_policy.codepipeline_policy,
    aws_iam_policy_attachment.codepipeline_policy_attachment,
  ]

  artifact_store {
    location = aws_s3_bucket.pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["${var.model_name}-source"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["${var.model_name}-source"]
      output_artifacts = ["${var.model_name}-build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }
}

# IAM permissions for the pipeline

resource "aws_iam_role" "codepipeline_role" {
  tags = { "name" = "${local.resource_prefix}-codepipeline-role" }
  name = "${local.resource_prefix}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "codepipeline_policy" {
  tags        = { "name" = "${local.resource_prefix}-codepipeline-policy" }
  name        = "${local.resource_prefix}-codepipeline-policy"
  description = "${local.resource_prefix} - CodePipeline Policy"
  path        = "/service-role/"

  policy = <<EOF
{
    "Statement": [
      {
          "Action": [
              "codebuild:StartBuild",
              "codebuild:BatchGetBuilds"
          ],
          "Resource": [
              "${aws_codebuild_project.build.arn}"
          ],
          "Effect": "Allow"
      },
      {
          "Action": [
              "s3:ListBucket",
              "s3:GetBucketPolicy",
              "s3:GetObjectAcl",
              "s3:PutObjectAcl",
              "s3:PutObject",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:GetBucketVersioning",
              "s3:DeleteObject"
          ],
          "Resource": [
              "${aws_s3_bucket.pipeline.arn}",
              "${aws_s3_bucket.pipeline.arn}/*"
          ],
          "Effect": "Allow"
      },
      {
        "Effect": "Allow",
        "Action": [
          "codestar-connections:UseConnection"
        ],
        "Resource": "${var.codestar_connection_arn}"
      }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy_attachment" "codepipeline_policy_attachment" {
  name       = "${local.resource_prefix}-codepipeline-policy-attachment"
  policy_arn = aws_iam_policy.codepipeline_policy.arn
  roles      = [aws_iam_role.codepipeline_role.id]
}

# S3 bucket to store pipeline artefacts

resource "aws_s3_bucket" "pipeline" {
  tags = { "name" = "codepipeline-${local.resource_prefix}" }

  bucket = "codepipeline-${local.resource_prefix}"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire-old-versions"
    enabled = "true"

    noncurrent_version_expiration {
      days = "180"
    }
  }
}
