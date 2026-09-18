resource "aws_iam_role" "eso" {
  name = "${local.name}-eso-iam"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}
resource "aws_iam_policy" "eso" {
  name = "${local.name}-eso-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = ["arn:aws:ssm:ap-southeast-1:465853822810:parameter/green-pulse/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = ["arn:aws:kms:ap-southeast-1:465853822810:alias/aws/ssm"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso" {
  role = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name = module.eks.cluster_name
  role_arn = aws_iam_role.eso.arn
  namespace = "external-secrets"
  service_account = "external-secrets"
}