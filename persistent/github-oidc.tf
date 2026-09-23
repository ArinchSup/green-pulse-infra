# Read the existing shared OIDC provider without claiming lifecycle ownership
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_ecr_push" {
  name = "green-pulse-github-ecr-push"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:ArinchSup/green-pulse:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_ecr_push" {
  name = "green-pulse-github-ecr-push"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
        ]
        Resource = [
          aws_ecr_repository.backend.arn,
          aws_ecr_repository.ai_service.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr_push" {
  role       = aws_iam_role.github_ecr_push.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}