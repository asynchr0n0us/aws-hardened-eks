output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca" {
  description = "EKS cluster CA certificate (base64)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — use for additional IRSA roles"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_issuer" {
  description = "OIDC issuer URL (without https://)"
  value       = local.oidc_issuer
}

output "vault_kms_key_arn" {
  description = "KMS key ARN used for Vault auto-unseal"
  value       = aws_kms_key.vault_unseal.arn
}

output "vault_iam_role_arn" {
  description = "IAM role ARN for Vault IRSA"
  value       = aws_iam_role.vault.arn
}

output "kubeconfig_command" {
  description = "Command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
