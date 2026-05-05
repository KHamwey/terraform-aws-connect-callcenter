provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "callcenter-demo"
      ManagedBy = "terraform"
      Owner     = "kwade"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
