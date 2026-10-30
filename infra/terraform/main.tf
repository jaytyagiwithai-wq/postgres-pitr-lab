data "aws_caller_identity" "current" {}

locals {
  bucket_name = "postgres-pitr-lab-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  common_tags = {
    Project     = "postgres-pitr-lab"
    Environment = "lab"
    ManagedBy   = "terraform"
    Purpose     = "postgresql-disaster-recovery"
  }
}

resource "aws_s3_bucket" "backup" {
  bucket        = local.bucket_name
  tags          = local.common_tags
  force_destroy = false
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "require_tls" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.backup.arn,
      "${aws_s3_bucket.backup.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "require_tls" {
  bucket = aws_s3_bucket.backup.id
  policy = data.aws_iam_policy_document.require_tls.json

  depends_on = [
    aws_s3_bucket_public_access_block.backup,
  ]
}


data "aws_iam_policy_document" "walg_assume_role" {
  statement {
    sid     = "AllowLabOperators"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }

}


resource "aws_iam_role" "walg" {
  name                 = "postgres-pitr-lab-walg"
  assume_role_policy   = data.aws_iam_policy_document.walg_assume_role.json
  max_session_duration = 3600

  tags = local.common_tags
}


data "aws_iam_policy_document" "walg_s3_access" {
  statement {
    sid    = "ReadBucketMetada"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [aws_s3_bucket.backup.arn]
  }

  statement {
    sid    = "ListPostgresBackupPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.backup.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "postgresql",
        "postgresql/*"
      ]
    }


  }
  statement {
    sid    = "ReadWritePostgresBackupObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${aws_s3_bucket.backup.arn}/postgresql/*"]
  }

}

resource "aws_iam_role_policy" "walg_s3_access" {
  name   = "postgres-pitr-lab-s3-access"
  role   = aws_iam_role.walg.id
  policy = data.aws_iam_policy_document.walg_s3_access.json
}
