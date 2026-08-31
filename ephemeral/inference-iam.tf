resource "aws_iam_policy" "inference" {
  name = "${local.name}-inference-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = ["s3:ListBucket"]
            Resource = [data.terraform_remote_state.persistent.outputs.weights_bucket_arn]
        },
        {
            Effect = "Allow"
            Action = ["s3:GetObject"]
            Resource = ["${data.terraform_remote_state.persistent.outputs.weights_bucket_arn}/*"]
        }
    ]
  })
}

resource "aws_iam_role" "inference" {
  name = "${local.name}-inference-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {Service = "pods.eks.amazonaws.com"}
        Action = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "inference" {
  role = aws_iam_role.inference.name
  policy_arn = aws_iam_policy.inference.arn
}

resource "aws_eks_pod_identity_association" "inference" {
  cluster_name = module.eks.cluster_name
  namespace = "default"
  service_account = "inference"
  role_arn = aws_iam_role.inference.arn
}