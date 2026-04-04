output "vpc_id" {
  description = "VoteChain VPC ID"
  value       = aws_vpc.votechain_vpc.id
}

#output "eks_cluster_endpoint" {
#  description = "EKS cluster endpoint"
#  value       = aws_eks_cluster.votechain_eks.endpoint
#}

#output "eks_cluster_name" {
#  description = "EKS cluster name"
#  value       = aws_eks_cluster.votechain_eks.name
#}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.votechain_db.endpoint
  sensitive   = true
}

output "audit_logs_bucket" {
  description = "S3 audit logs bucket name"
  value       = aws_s3_bucket.audit_logs.bucket
}

#output "kms_key_arn" {
#  description = "KMS key ARN for vote encryption"
#  value       = aws_kms_key.votechain_key.arn
#  sensitive   = true
#}
