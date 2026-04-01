############ terraform.auto.tfvars ############


############ General ############

aws_region   = "eu-west-1"
project_name = "eks-hardened"
environment  = "develop"

############ Networking — fill with your VPC/subnet IDs ############
vpc_id = "vpc-0dcbdc87efbc3b476"
private_subnet_ids = [
  "subnet-07517c32492db44f5",
  "subnet-020a1ff8ea1b18fb2",
  "subnet-03dd008a67aa881ef",
]

############ Public endpoint disabled in prod, allowed in staging for convenience ############
enable_public_endpoint = true
allowed_cidrs          = ["87.8.39.227/32"]

############ EKS ############
kubernetes_version = "1.32"
log_retention_days = 30

############ Node Group ############
node_instance_types = ["t3.medium"]  
node_desired        = 2
node_min            = 1
node_max            = 5
node_disk_size_gb   = 30

############ Helm chart versions (avoid unattended upgrades) ############
falco_chart_version            = "4.18.0"
trivy_chart_version            = "0.21.0"
gatekeeper_chart_version       = "3.16.0"
external_secrets_chart_version = "0.9.0"
vault_chart_version            = "0.27.0"

############ Vault ############
vault_storage_size   = "10Gi"
vault_cpu_request    = "250m"
vault_cpu_limit      = "1000m"
vault_memory_request = "256Mi"
vault_memory_limit   = "512Mi"

############ Alerting ############
# slack_webhook_url — set via TF_VAR_slack_webhook_url env var (sensitive)
# export TF_VAR_slack_webhook_url="https://hooks.slack.com/services/..."
