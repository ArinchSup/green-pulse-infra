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
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "weights" {
  bucket                  = aws_s3_bucket.weights.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}