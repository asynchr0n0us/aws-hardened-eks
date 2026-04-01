############ Falco runtime security (eBPF driver) ############
resource "helm_release" "falco" {
  name             = "falco"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falco"
  version          = "8.0.1"
  namespace        = "falco"
  create_namespace = true
  timeout          = 600

  set {
    name  = "driver.kind"
    value = "modern_ebpf"
  }

  set {
    name  = "tty"
    value = "true"
  }

  set {
    name  = "containerSecurityContext.privileged"
    value = "true"
  }

  set {
    name  = "falcosidekick.enabled"
    value = "true"
  }

  set {
    name  = "falcosidekick.config.slack.webhookurl"
    value = var.slack_webhook_url
  }

  set {
    name  = "falcosidekick.config.slack.minimumpriority"
    value = "warning"
  }

  set {
    name  = "falcosidekick.config.slack.messageformat"
    value = "Falco alert on <{{.Hostname}}> — rule: {{.Rule}}"
  }

  depends_on = [aws_eks_node_group.main]
}

############ Trivy image vulnerability scanning ############
resource "helm_release" "trivy_operator" {
  name             = "trivy-operator"
  repository       = "https://aquasecurity.github.io/helm-charts/"
  chart            = "trivy-operator"
  version          = var.trivy_chart_version
  namespace        = "trivy-system"
  create_namespace = true

  set {
    name  = "trivy.ignoreUnfixed"
    value = "true"
  }

  set {
    name  = "operator.scanJobTimeout"
    value = "5m"
  }

  set {
    name  = "operator.scanJobsInSameNamespace"
    value = "false"
  }

  depends_on = [aws_eks_node_group.main]
}

############ OPA Gatekeeper container no root policy enforcement ############
resource "helm_release" "gatekeeper" {
  name             = "gatekeeper"
  repository       = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart            = "gatekeeper"
  version          = var.gatekeeper_chart_version
  namespace        = "gatekeeper-system"
  create_namespace = true

  set {
    name  = "auditInterval"
    value = "30"
  }

  set {
    name  = "constraintViolationsLimit"
    value = "20"
  }

  set {
    name  = "logLevel"
    value = "WARNING"
  }

  depends_on = [aws_eks_node_group.main]
}

############ External Secrets sync secrets from AWS Secrets Manager ############
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [aws_eks_node_group.main]
}

##### Cert Manager ########

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.17.2"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  depends_on = [aws_eks_node_group.main]
}
