terraform {
  required_version = ">= 0.12.26"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.69.0"
    }
    null = {
      source = "hashicorp/null"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}



provider "aws" {
  profile = local.profile
  alias   = "eyewa-uat"
  region  = local.region
}

provider "aws" {
  profile = local.profile_s3
  alias   = "s3-state"
  region  = local.region
}

provider "aws" {
  region = "ap-southeast-1"
}


