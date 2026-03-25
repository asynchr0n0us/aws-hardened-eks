terraform {
  required_version = ">= 1.6"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.0" }
    tls        = { source = "hashicorp/tls", version = "~> 4.0" }
  }
  backend "s3" {
    bucket         = "bucket-for-tfstate-here"
    key            = "eks/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

############ Providers ############

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}


############ Data sources ############

data "aws_eks_cluster" "main" { name = aws_eks_cluster.main.name }
data "aws_eks_cluster_auth" "main" { name = aws_eks_cluster.main.name }


############ Locals value calc ############

locals {
  cluster_name = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
