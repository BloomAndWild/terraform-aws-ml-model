resource "aws_ecr_repository" "this" {
  name                 = "${var.model_name}/app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
