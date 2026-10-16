# resource "aws_ecr_repository" "artifactory" {
#   name                 = "devop-registry"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# resource "aws_ecr_repository" "frontend" {
#   name                 = "devop-registry-frontend"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

