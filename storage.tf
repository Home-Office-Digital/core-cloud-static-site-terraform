resource "aws_s3_bucket" "static_site" {
  bucket = "cc-static-site-${var.tenant_vars.product}-${var.tenant_vars.component}"

  tags = local.common_tags
}

resource "aws_s3_bucket" "static_site_logs" {
  bucket = "cc-static-site-logs-${var.tenant_vars.product}-${var.tenant_vars.component}"

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "static_site_logs_acl" {
  bucket = aws_s3_bucket.static_site_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "static_site_logs_ownership" {
  bucket = aws_s3_bucket.static_site_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# CKV_AWS_18 - S3 access logging
resource "aws_s3_bucket_logging" "static_site_logging" {
  bucket        = aws_s3_bucket.static_site.id
  target_bucket = aws_s3_bucket.static_site_logs.id
  target_prefix = "s3-access-logs/"
}

# CKV2_AWS_61 - lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "static_site_lifecycle" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_site_acl" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "static_site_versioning" {
  bucket = aws_s3_bucket.static_site.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_site_encryption" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.static_site_kms.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

data "aws_iam_policy_document" "static_site_iam_storage_policy_document" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.static_site.id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.static_site_distribution.arn]
    }
  }
  statement {
    sid    = "AllowCloudFrontServicePrincipalListBucket"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.static_site.id}"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.static_site_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket     = aws_s3_bucket.static_site.id
  policy     = data.aws_iam_policy_document.static_site_iam_storage_policy_document.json
  depends_on = [aws_s3_bucket_public_access_block.static_site_acl]
}
