module "karpenter" {
  node_iam_role_name            = "${local.name}-karpenter-node"
  node_iam_role_use_name_prefix = false
  source                        = "terraform-aws-modules/eks/aws//modules/karpenter"
  version                       = "~> 21.0"
  enable_inline_policy = true

  cluster_name = module.eks.cluster_name

  create_pod_identity_association = true
  enable_spot_termination         = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}