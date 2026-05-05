terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.26, < 6.0"
    }
    # awscc covers AWS::Lex::ResourcePolicy (no equivalent in hashicorp/aws yet)
    # for granting Connect permission to invoke the Lex V2 bot alias.
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
}
