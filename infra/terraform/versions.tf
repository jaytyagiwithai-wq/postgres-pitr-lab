terraform {
  required_version = ">=1.8 , < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

#Required providers -> download the AWS provider plugins
#provider aws -> configure that provider for our acc/region