resource "aws_wafv2_ip_set" "allow_ip_set" {
  name               = "allow-ip-set"
  description        = "IP set to allow"
  scope              = "REGIONAL" # Or CLOUDFRONT
  ip_address_version = "IPV4"

  addresses = [
    "${aws_instance.windows_server.public_ip}/32" # Replace with instance IP
  ]
}

resource "aws_wafv2_web_acl" "waf_acl" {
  name        = "ip-restrict-waf"
  description = "WAF to allow specific IP and block others"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "iprestrictwaf"
    sampled_requests_enabled   = true
  }

  # IP Allow Rule
  rule {
    name     = "AllowSpecificIP"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allow_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowSpecificIP"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "waf_alb_association" {
  resource_arn = aws_lb.app_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
}
