resource "null_resource" "vault_tls" {
  depends_on = [helm_release.cert_manager]

  provisioner "local-exec" {
    command = <<-EOF
      kubectl apply -f - <<YAML
      apiVersion: cert-manager.io/v1
      kind: Issuer
      metadata:
        name: vault-selfsigned
        namespace: vault
      spec:
        selfSigned: {}
      ---
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: vault-tls
        namespace: vault
      spec:
        secretName: vault-tls
        issuerRef:
          name: vault-selfsigned
          kind: Issuer
        commonName: vault.vault.svc.cluster.local
        dnsNames:
          - vault
          - vault.vault
          - vault.vault.svc
          - vault.vault.svc.cluster.local
          - "*.vault-internal"
          - "*.vault-internal.vault.svc.cluster.local"
        ipAddresses:
          - "127.0.0.1"
      YAML
    EOF
  }
}