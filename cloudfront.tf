resource "aws_cloudfront_origin_access_control" "static_site_identity" {
  name                              = "cc-static-site-${var.tenant_vars.product}-${var.tenant_vars.component}"
  description                       = "Origin access control for ${var.tenant_vars.product} ${var.tenant_vars.component}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static_site_distribution" {
  #checkov:skip=CKV_AWS_310:Static site distribution uses a single S3 origin and does not require origin failover
  #checkov:skip=CKV_AWS_86:CloudFront access logging is managed outside this module
  #checkov:skip=CKV_AWS_374:Static sites are intentionally globally accessible without geo restrictions
  #checkov:skip=CKV2_AWS_47:WAF rules are managed in the external WebACL passed via var.waf_acl_id
  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.static_site.id
    origin_access_control_id = aws_cloudfront_origin_access_control.static_site_identity.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront distribution for ${var.tenant_vars.product} ${var.tenant_vars.component}"
  default_root_object = "index.html"

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  aliases = var.tenant_vars.cloudfront_aliases

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_site.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 86400
    response_headers_policy_id = var.enable_security_headers ? aws_cloudfront_response_headers_policy.security_headers[0].id : null  # ADDED


    function_association {
      event_type   = "viewer-request"
      function_arn = var.cloudfront_function_rewrite_arn
    }

  }

  custom_error_response {
    error_code            = 404
    response_page_path    = "/404.html" # Path to your custom error page
    response_code         = 404
    error_caching_min_ttl = 10 # Cache TTL in seconds
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = var.cloud_front_default_vars.cloudfront_price_class

  tags = local.common_tags

  viewer_certificate {
    acm_certificate_arn            = var.tenant_vars.cloudfront_cert
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = "false"
    ssl_support_method             = "sni-only"
  }
  web_acl_id = var.waf_acl_id
}
