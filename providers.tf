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

provider "awscc" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
