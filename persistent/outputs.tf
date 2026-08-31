output "backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ai_service_repository_url" {
  value = aws_ecr_repository.ai-service.repository_url
}

output "weights_bucket_name" {
  description = "The name of the S3 bucket storing model weights"
  value       = aws_s3_bucket.weights.id
}

output "weights_bucket_arn" {
  value = aws_s3_bucket.weights.arn
}