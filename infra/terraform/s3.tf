resource "aws_s3_bucket" "audit_logs" {
  bucket = "${var.project_name}-audit-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "${var.project_name}-audit-logs"
    Purpose = "Immutable audit trail for all votes"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

#resource "aws_s3_bucket_versioning" "audit_logs_versioning" {
#  bucket = aws_s3_bucket.audit_logs.id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}

#resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs_encryption" {
#  bucket = aws_s3_bucket.audit_logs.id

#  rule {
#    apply_server_side_encryption_by_default {
#      sse_algorithm     = "aws:kms"
#      kms_master_key_id = aws_kms_key.votechain_key.arn
#    }
#  }
#}

#resource "aws_s3_bucket_public_access_block" "audit_logs_public_access" {
#  bucket = aws_s3_bucket.audit_logs.id

# block_public_acls       = true
# block_public_policy     = true
# ignore_public_acls      = true
# restrict_public_buckets = true
#}

#"resource "aws_s3_bucket_lifecycle_configuration" "audit_logs_lifecycle" {
#  bucket = aws_s3_bucket.audit_logs.id
#
#  rule {
#    id     = "archive-old-logs"
#    status = "Enabled"
#
#    filter {}
#
#    transition {
#      days          = 90
#      storage_class = "STANDARD_IA"
#    }
#
#    transition {
#      days          = 365
#      storage_class = "GLACIER"
#    }
#  }
#}"
