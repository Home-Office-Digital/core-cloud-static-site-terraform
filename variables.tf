variable "waf_acl_id" {
  type        = string
  description = "ARN of the waf to be attached to the cloudfront."
}

variable "tenant_vars" {
  type = object({
    # enforced tags, all required attributes for costing and ID
    cost_centre  = string
    account_code = string
    portfolio_id = string
    project_id   = string
    service_id   = string

    # other attributes, required for cloudfront creation
    repositories            = list(string)
    github_environment_name = string
    cloudfront_aliases      = list(string)
    cloudfront_cert         = string

    #required for naming of resources
    #e.g. "cc-static-site-${var.tenant_vars.product}-${var.tenant_vars.component}"
    component = string
    product   = string
  })
}

variable "cloudfront_function_rewrite_arn" {
  type        = string
  description = "ARN for the Cloudfront function"
}

variable "cloud_front_default_vars" {
  type = any
}

variable "aws_region" {
  type = string
}
