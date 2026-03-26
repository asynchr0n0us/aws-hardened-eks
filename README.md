# Hardened EKS - Terraform + GitOps

Hardened EKS cluster with Falco runtime security, Trivy scanning, OPA/Gatekeeper policies, RBAC and network policies.

# Architecture

```
EKS Cluster private API endpoint
- Node Groups (private subnets, Bottlerocket OS)
- Falco (DaemonSet) — runtime threat detection
- Trivy Operator — continuous image scanning
- OPA Gatekeeper — policy enforcement
- Kyverno — admission controller policies
- Cert-manager — TLS certificate automation
- HashiCorp Vault (HA, 3 replicas) — secrets management + auto-unseal via AWS KMS
  Vault Agent Injector — sidecar injection into pods
  Sync from AWS Secrets Manager
```

# Security Features

- **EKS private endpoint** — API server not exposed to internet
- **Bottlerocket OS** — security-hardened, read-only root FS
- **IMDSv2 required** — prevents SSRF metadata attacks
- **Calico network policies** — default deny, explicit allow
- **OPA Gatekeeper** — enforce no-root containers, resource limits, approved registries
- **Falco** — runtime anomaly detection (syscall level)
- **Trivy Operator** — scan all running images continuously
- **HashiCorp Vault (HA)** — centralised secrets management, dynamic credentials, auto-unseal via AWS KMS, Vault Agent sidecar injection
- **Secrets Manager** via External Secrets Operator — no secrets in k8s etcd plain text
- **Pod Security Standards** — Restricted profile enforced
- **IRSA** — IAM Roles for Service Accounts (no node-level credentials)

# Prerequisites

- Terraform >= 1.6
- AWS CLI configured with management account credentials
- tflint
- trivy
- checkov
- `pre-commit` installed locally

# tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# trivy
sudo apt install wget apt-transport-https gnupg -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -

echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update && sudo apt install trivy -y

# checkov
pip install checkov --break-system-packages

# pre-commit install
python3 -m venv

source /path/to/venv/bin/activate

pip install pre-commit

cd /into/the/project/dir

pre-commit install

# Usage

```bash
# Deploy EKS cluster + all Helm releases (Falco, Trivy, Gatekeeper, Vault, External Secrets)
terraform init
terraform plan
terraform apply

# Apply OPA Gatekeeper and network policies
kubectl apply -f policies/
```

# Estimated Monthly Cost

| Resource                    | Est. Cost |
|-----------------------------|-----------|
| EKS Control Plane           | ~$73      |
| Node Group (2x t3.medium)   | ~$60      |
| NAT Gateway                 | ~$33      |
| **Total**                   | **~$166** |
