// Infra/main.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-b26-workshop1"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
  required_version = ">= 1.5.0"
  required_providers {
    aws        = { source = "hashicorp/aws",        version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.27" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.11.0" }
    http       = { source = "hashicorp/http",       version = ">= 3.4.0" }
    tls        = { source = "hashicorp/tls",        version = ">= 4.0.0" }
  }
}

provider "aws" {
  region = var.region
}

###############################################
# Read VPC/Subnet outputs from Network layer
###############################################
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-state-b26-workshop1"
    key    = "envs/dev/network.tfstate"
    region = "us-east-2"
  }
}

locals {
  vpc_id               = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids    = data.terraform_remote_state.network.outputs.public_subnet_ids
  web_tier_subnet_ids  = data.terraform_remote_state.network.outputs.web_tier_subnet_ids
  app_tier_subnet_ids  = data.terraform_remote_state.network.outputs.app_tier_subnet_ids
  data_tier_subnet_ids = data.terraform_remote_state.network.outputs.data_tier_subnet_ids
}


module "tf_ecr" {
  source           = "../modules/tf-ecr"
  repository_names = var.ecr_repository_names
  tags             = var.tags
}

# Added module to resolve backend_alb_sg_id reference in EKS
module "backend_alb_sg" {
  source = "../modules/tf-backend-alb-sg"
  vpc_id = local.vpc_id
  ecs_security_group_id = ""
  tags   = var.tags
}

# Added module to resolve module.tf_alb references in outputs.tf
module "tf_alb" {
  source            = "../modules/tf-alb"
  vpc_id            = local.vpc_id
  public_subnet_ids = local.public_subnet_ids
  acm_certificate_arn = var.acm_certificate_arn # <-- ADDED: Passes required certificate ARN
  tags              = var.tags
}

module "tf_eks" {
  source            = "../modules/tf-eks"
  eks_cluster_name  = var.eks_cluster_name
  eks_version       = var.eks_version
  vpc_id            = local.vpc_id
  subnet_ids        = local.app_tier_subnet_ids
  backend_alb_sg_id = module.backend_alb_sg.backend_alb_sg_id
  tags              = var.tags
}

module "tf_rds" {
  source            = "../modules/tf-rds"
  vpc_id            = local.vpc_id
  eks_nodes_sg_id   = module.tf_eks.tf_eks_cluster_security_group_id
  data_subnet_ids   = local.data_tier_subnet_ids
  db_username       = var.db_username
  db_password       = var.db_password
  db_name           = var.db_name
  db_instance_class = var.db_instance_class
  tags              = var.tags
}
