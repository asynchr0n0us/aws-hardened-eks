############ KMS key for Vault ############

resource "aws_kms_key" "vault_unseal" {
  description             = "Vault auto-unseal - ${local.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/${local.cluster_name}-vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

############ IAM Role for Vault ############

resource "aws_iam_role" "vault" {
  name        = "${local.cluster_name}-vault-role"
  description = "Vault IRSA role - KMS unseal only"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:vault:vault"
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "vault_kms" {
  name = "${local.cluster_name}-vault-kms-policy"
  role = aws_iam_role.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "VaultKMSUnseal"
      Effect = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
      ]
      # Scoped to vault unseal key only — not wildcard
      Resource = aws_kms_key.vault_unseal.arn
    }]
  })
}

############ HashiCorp Vault HA mode ############

resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = var.vault_chart_version
  namespace        = "vault"
  create_namespace = true

  values = [yamlencode({
    global = {
      tlsDisable = false # TLS enabled — cert-manager issues the certificate
    }

    server = {
      # HA mode with Raft integrated storage — 3 replicas
      ha = {
        enabled  = true
        replicas = 3

        raft = {
          enabled   = true
          setNodeId = true # setNodeId=true handles node_id automatically via HOSTNAME env var

          config = <<-EOF
            ui = true

            listener "tcp" {
              tls_cert_file = "/vault/userconfig/vault-tls/tls.crt"
              tls_key_file  = "/vault/userconfig/vault-tls/tls.key"
              address       = "[::]:8200"
              cluster_address = "[::]:8201"
            }

            storage "raft" {
              path = "/vault/data"
            }

            seal "awskms" {
              region     = "${var.aws_region}"
              kms_key_id = "${aws_kms_key.vault_unseal.id}"
            }

            service_registration "kubernetes" {}
          EOF
        }
      }

      # Persistent Raft storage — gp3, encrypted at rest via EBS
      dataStorage = {
        enabled      = true
        size         = var.vault_storage_size
        storageClass = "gp3"
      }

      # IRSA annotation — grants KMS access via pod identity
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.vault.arn
        }
      }

      # Security context — non-root, read-only where possible
      securityContext = {
        runAsNonRoot = true
        runAsUser    = 100
        fsGroup      = 1000
        capabilities = { drop = ["ALL"] }
      }

      resources = {
        requests = { cpu = var.vault_cpu_request, memory = var.vault_memory_request }
        limits   = { cpu = var.vault_cpu_limit, memory = var.vault_memory_limit }
      }

      readinessProbe = {
        enabled             = true
        initialDelaySeconds = 5
        periodSeconds       = 5
        path                = "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
      }

      livenessProbe = {
        enabled             = true
        initialDelaySeconds = 60
        periodSeconds       = 10
        path                = "/v1/sys/health?standbyok=true"
      }

      # Affinity — spread replicas across AZs
      affinity = yamlencode({
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [{
            labelSelector = {
              matchLabels = { "app.kubernetes.io/name" = "vault" }
            }
            topologyKey = "topology.kubernetes.io/zone"
          }]
        }
      })
    }

    # Vault Agent Injector — injects secrets as sidecar into annotated pods
    injector = {
      enabled = true
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "250m", memory = "256Mi" }
      }
    }

    # Vault UI — ClusterIP only, access via kubectl port-forward or ingress
    ui = {
      enabled     = true
      serviceType = "ClusterIP"
    }
  })]

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy.vault_kms,
    aws_iam_openid_connect_provider.eks,
  ]
}
