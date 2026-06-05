resource "aws_cloudfront_response_headers_policy" "security_headers" {
  count   = var.enable_security_headers ? 1 : 0
  name    = "cc-static-site-security-headers-${var.tenant_vars.product}-${var.tenant_vars.component}"
  comment = "Security headers for ${var.tenant_vars.product} ${var.tenant_vars.component}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    content_security_policy {
      content_security_policy = "default-src 'self'; upgrade-insecure-requests;"
      override                = false
    }
  }
}