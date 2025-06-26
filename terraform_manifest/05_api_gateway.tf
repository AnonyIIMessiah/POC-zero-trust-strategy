# API Gateway (HTTP API v2)
resource "aws_apigatewayv2_api" "api" {
  name          = "api-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
    allow_methods     = ["*"] # Keep this as it tells the browser which methods are allowed generally
    allow_origins     = ["http://localhost:3000", "https://${aws_lb.app_lb.dns_name}"]
    allow_credentials = true
    expose_headers    = []
    max_age           = 300
  }
}

# Lambda Permissions to allow API Gateway to invoke
resource "aws_lambda_permission" "api_gw_users" {
  statement_id  = "AllowAPIGatewayInvokeUsers"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user-service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

resource "aws_lambda_permission" "api_gw_products" {
  statement_id  = "AllowAPIGatewayInvokeProducts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product-service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

# Integration for Users Lambda 
resource "aws_apigatewayv2_integration" "lambda_integration_users" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.user-service.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# OPTIONS /users route (no authorization needed for preflight)
resource "aws_apigatewayv2_route" "options_users" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "OPTIONS /users"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}" 
  authorization_type = "NONE"                                                                     
}

# Route for ANY /users (actual requests with JWT authorization)
resource "aws_apigatewayv2_route" "users_any" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /users"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}

# Route for OPTIONS /users/{id}
resource "aws_apigatewayv2_route" "options_users_with_id" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "OPTIONS /users/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}" 
  authorization_type = "NONE"                                                                     
}

# Route for ANY /users/{id}
resource "aws_apigatewayv2_route" "users_with_id_any" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /users/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}


# Integration for Products Lambda 
resource "aws_apigatewayv2_integration" "lambda_integration_products" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.product-service.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route for OPTIONS /products
resource "aws_apigatewayv2_route" "options_products" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "OPTIONS /products"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}" 
  authorization_type = "NONE"                                                                        
}

# Route for ANY /products
resource "aws_apigatewayv2_route" "products_any" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /products"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}

# Route for OPTIONS /products/{id}
resource "aws_apigatewayv2_route" "options_products_with_id" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "OPTIONS /products/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}" 
  authorization_type = "NONE"                                                                        
}

# Route for ANY /products/{id}
resource "aws_apigatewayv2_route" "products_with_id_any" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /products/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}

# Deploy stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Output the API URL 
output "api_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}