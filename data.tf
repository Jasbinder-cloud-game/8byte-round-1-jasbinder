data "aws_ecr_repository" "backend" {
  name = "jasbinder/backend-registry"
}

data "aws_ecr_repository" "frontend" {
  name = "jasbinder/frontend-registry"
}