# In this file put all the logic to crete the proper infraestructure
terraform {
  required_version = ">= 1.11.0"
  required_providers {
    # Add the provideres according to the challenges
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {

  }
}