variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}