############ Template (Bottlerocket + IMDSv2 + encrypted EBS) ############

resource "aws_launch_template" "nodes" {
  name_prefix = "${local.cluster_name}-nodes-"
  description = "EKS node launch template — IMDSv2 required, encrypted gp3"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 — prevents SSRF metadata attacks
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  lifecycle {
    create_before_destroy = true
  }
}

############ Managed Node Group ############

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

############ Bottlerocket security-hardened OS, read-only root FS, automatic updates ############

  ami_type       = "BOTTLEROCKET_x86_64"
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired
    max_size     = var.node_max
    min_size     = var.node_min
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  depends_on = [aws_iam_role_policy_attachment.node_group]

  lifecycle {
    # Ignore desired_size changes — managed by Cluster Autoscaler
    ignore_changes = [scaling_config[0].desired_size]
  }
}
