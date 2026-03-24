############ IAM EKS Control Plane Role ############

resource "aws_iam_role" "eks_cluster" {
  name        = "${local.cluster_name}-cluster-role"
  description = "EKS control plane role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])
  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}


############ IAM Node Group Role (least privilege) ############

resource "aws_iam_role" "node_group" {
  name        = "${local.cluster_name}-node-role"
  description = "EKS node group role — least privilege"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_group" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    # SSM Session Manager — allows shell access to nodes without SSH keys
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    # EBS CSI driver — required to mount gp3 PVCs (e.g. Vault Raft storage)
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
  ])
  role       = aws_iam_role.node_group.name
  policy_arn = each.value
}


############ OIDC Provider (IAM Roles for Service Accounts) ############


data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}


############ Remove https:// prefix on OIDC url ############

locals {
  oidc_issuer = replace(
    aws_eks_cluster.main.identity[0].oidc[0].issuer,
    "https://", ""
  )
}
