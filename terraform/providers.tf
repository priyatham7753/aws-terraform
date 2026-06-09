provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}



# provider "aws" {
#   region = var.aws_region

#   default_tags {
#     tags = {
#       Project     = var.project_name
#       Environment = var.environment
#       ManagedBy   = "Terraform"
#     }
#   }
# }

# # provider "random" {}


# terraform {
#   required_providers {
#     aws = {
#         source = "registry.terraform.io/hashicorp/aws"
#         version = "6.44.0"
#     }
#   }
# }


