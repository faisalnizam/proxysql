terraform {
  backend "s3" {
    bucket  = "eyewacore-master-ap-southeast-1-tfstates"
    key     = "ou/application/uat/terraform.tfstate"
    region  = "ap-southeast-1"
    profile = "eyewa_s3"
  }
}

