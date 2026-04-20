data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "static_site_actions_push" {
  name = "cc-static-site-${var.tenant_vars.product}-${var.tenant_vars.component}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated : "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : [for repo in var.tenant_vars.repositories : "repo:${repo}:environment:${var.tenant_vars.github_environment_name}"]
            "sts:RoleSessionName" : "GitHubActions"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        },
      }
    ]
  })
  tags = local.common_tags
}


resource "aws_iam_role_policy_attachment" "static_site_policy_attachment" {
  policy_arn = aws_iam_policy.static_site_policy.arn
  role       = aws_iam_role.static_site_actions_push.name
}

resource "aws_iam_policy" "static_site_policy" {
  name   = "static-site-${var.tenant_vars.component}-iam-policy"
  policy = data.aws_iam_policy_document.static_site_policy_document.json
}

data "aws_iam_policy_document" "static_site_policy_document" {
  statement {
    sid = "WriteToBucket"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectVersionTagging",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListMultipartUploadParts",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionAcl",
      "s3:PutObjectVersionTagging",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.static_site.id}",
      "arn:aws:s3:::${aws_s3_bucket.static_site.id}/*"
    ]
  }
  statement {
    sid = "KMS"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo"
    ]

    resources = [
      aws_kms_key.static_site_kms.arn,
    ]
  }
  statement {
    sid = "Cloudfront"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      aws_cloudfront_distribution.static_site_distribution.arn,
    ]
  }
}
