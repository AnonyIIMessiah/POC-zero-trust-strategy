resource "aws_cognito_user_pool" "user_pool" {
  name = "myapp-user-pool"

  auto_verified_attributes = ["email"]
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name            = "myapp-client"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  explicit_auth_flows                  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = ["https://${aws_lb.app_lb.dns_name}/callback"]
  logout_urls   = ["https://${aws_lb.app_lb.dns_name}/logout"]
  # callback_urls = ["https://ec2-65-1-134-229.ap-south-1.compute.amazonaws.com/callback"]
  # logout_urls   = ["https://ec2-65-1-134-229.ap-south-1.compute.amazonaws.com/logout"]
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "myapp-auth-domain-jpaihg" # ✅ lowercase only
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "random_string" "suffix" {
  length  = 6
  special = false
}

resource "aws_apigatewayv2_authorizer" "jwt_auth" {
  name             = "cognito-authorizer"
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.user_pool_client.id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  }
}


variable "region" {
  default = "ap-south-1"
}
