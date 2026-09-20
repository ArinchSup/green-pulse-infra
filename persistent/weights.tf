resource "aws_s3_bucket" "weights" {
  bucket = "green-pulse-model-weights-465853822810"
}

resource "aws_s3_bucket_versioning" "weights" {
  bucket = aws_s3_bucket.weights.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "weights" {
  bucket = aws_s3_bucket.weights.id

  rule {
    id     = "expire non-current version"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}