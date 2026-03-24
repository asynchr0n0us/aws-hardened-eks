############ General ############

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name — used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev / staging / prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging or prod."
  }
}

############ Networking ############

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "enable_public_endpoint" {
  description = "Expose EKS API endpoint publicly (false in prod)"
  type        = bool
}

variable "allowed_cidrs" {
  description = "CIDRs allowed to reach the public EKS endpoint"
  type        = list(string)
  default     = []
}

############ EKS ############

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

############ Node Group ############
variable "node_instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
}

variable "node_desired" {
  description = "Desired number of nodes"
  type        = number
}

variable "node_min" {
  description = "Minimum number of nodes"
  type        = number
}

variable "node_max" {
  description = "Maximum number of nodes"
  type        = number
}

variable "node_disk_size_gb" {
  description = "EBS root volume size in GB per node"
  type        = number
}

############ Helm chart versions ############
variable "falco_chart_version" {
  description = "Falco Helm chart version"
  type        = string
}

variable "trivy_chart_version" {
  description = "Trivy Operator Helm chart version"
  type        = string
}

variable "gatekeeper_chart_version" {
  description = "OPA Gatekeeper Helm chart version"
  type        = string
}

variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version"
  type        = string
}

variable "vault_chart_version" {
  description = "HashiCorp Vault Helm chart version"
  type        = string
}

############ Vault ############
variable "vault_storage_size" {
  description = "Vault Raft storage PVC size (e.g. 10Gi)"
  type        = string
}

variable "vault_cpu_request" {
  description = "Vault server CPU request"
  type        = string
}

variable "vault_cpu_limit" {
  description = "Vault server CPU limit"
  type        = string
}

variable "vault_memory_request" {
  description = "Vault server memory request"
  type        = string
}

variable "vault_memory_limit" {
  description = "Vault server memory limit"
  type        = string
}

############ Observability / alerting ############
variable "slack_webhook_url" {
  description = "Slack webhook URL for Falco alerts"
  type        = string
  sensitive   = true
  default     = ""
}
