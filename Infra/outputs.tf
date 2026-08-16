// VPC Outputs

output "region" {
  value = var.region
}

output "vpc_id" {
  value = var.vpc_id
}

output "public_subnet_ids" {
  value = var.public_subnet_ids
}

output "app_tier_subnet_ids" {
  value = var.app_tier_subnet_ids
}

// ECR Outputs 

output "ecr_repo_urls" {
  description = "Map repo_name => repository URL"
  value       = module.tf_ecr.repo_urls
}

output "ecr_repo_arns" {
  description = "Map repo_name => repository ARN"
  value       = module.tf_ecr.repo_arns
}

// EKS Outputs 

output "eks_control_plane_sg_id" {
  description = "Default EKS control plane security group ID created automatically by AWS"
  value       = module.tf_eks.tf_eks_cluster_security_group_id
}

output "eks_cluster_endpoint" {
  value = module.tf_eks.tf_eks_cluster_endpoint
}

output "eks_cluster_ca_data" {
  value = module.tf_eks.tf_eks_cluster_ca_data
}

output "eks_cluster_name" {
  value = module.tf_eks.tf_eks_cluster_name
}

// Frontend ALB Outputs 

output "alb_dns_name" {
  value = module.tf_alb.alb_dns_name
}

output "alb_sg_id" {
  description = "Security group ID of the frontend ALB"
  value       = module.tf_alb.alb_sg_id 
}
