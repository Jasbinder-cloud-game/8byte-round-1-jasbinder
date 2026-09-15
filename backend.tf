terraform {
  backend "s3" {
    bucket = "tf-state-backend-jumbo"
    key    = "terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}
