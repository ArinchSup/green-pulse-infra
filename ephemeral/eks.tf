module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.name}-cluster"
  kubernetes_version = "1.36"

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    general = {
      instance_types = ["m7i-flex.large"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1

      ami_type = "AL2023_x86_64_STANDARD"
    }
  }
  addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni = {
      before_compute = true
    }
  }
  upgrade_policy = {
    support_type = "STANDARD"
  }
}