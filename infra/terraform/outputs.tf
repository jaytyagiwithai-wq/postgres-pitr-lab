output "backup_bucket_name" {
  description = "S3 bucket used by WAL-G."
  value       = aws_s3_bucket.backup.id
}

output "walg_s3_prefix" {
  description = "S3 prefix used by WAL-G."
  value       = "s3://${aws_s3_bucket.backup.id}/postgresql"
}

output "walg_role_arn" {
  description = "IAM role assumed by the local WAL-G process."
  value       = aws_iam_role.walg.arn
}