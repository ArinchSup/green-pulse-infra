resource "aws_s3_bucket" "weights" {
  bucket = "green-pulse-model-weights-465853822810"
}

resource "aws_s3_bucket_versioning" "weights" {
  bucket = aws_s3_bucket.weights.id
  versioning_configuration {
    status = "Enabled"
  }
}