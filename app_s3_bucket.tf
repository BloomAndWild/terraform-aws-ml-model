resource "aws_s3_bucket" "app" {
  tags = { "name" = "${local.application_s3_bucket}" }

  # We use a different naming convention for this bucket
  # Long term we want to move all pipelines to a single
  # bucket and use prefixes per project
  bucket = local.application_s3_bucket
  acl    = "private"
}
