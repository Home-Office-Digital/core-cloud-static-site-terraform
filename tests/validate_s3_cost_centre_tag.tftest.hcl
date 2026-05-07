
mock_provider "aws" {}
mock_provider "aws" {
  alias = "us-east-1"
}

run "plan_only" {
  command = plan

  # Supply required input variables for the root module under test
  variables {
    waf_acl_id = ""
    tenant_vars = {
      cost_centre             = "test-cc"
      account_code            = "AC123"
      portfolio_id            = "pf-1"
      project_id              = "proj-1"
      service_id              = "svc-1"
      repositories            = ["org/repo"]
      github_environment_name = "prod"
      cloudfront_aliases      = []
  cloudfront_cert         = "arn:aws:acm:us-east-1:000000000000:certificate/12345678-1234-1234-1234-123456789012"
      component               = "comp"
      product                 = "prod"
    }
    cloudfront_function_rewrite_arn = ""
    cloud_front_default_vars        = { cloudfront_price_class = "PriceClass_100" }
    aws_region                      = "us-east-1"
  }

// TEST 1: Assert S3 bucket 'cost-centre' tag equals 'test-cc' (plan-only)
// Why: prevents accidental removal or changes to enforced tags used for billing and identification.
  assert {
    condition = aws_s3_bucket.static_site.tags["cost-centre"] == "test-cc"
    error_message = "Enforced tag 'cost-centre' not propagated to S3 bucket"
  }
}
