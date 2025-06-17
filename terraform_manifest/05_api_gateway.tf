# # API Gateway (HTTP API v2)
# resource "aws_apigatewayv2_api" "api" {
#   name          = "api-gateway"
#   protocol_type = "HTTP"
#   cors_configuration {
#     allow_headers = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
#     allow_methods = ["*"] # Keep this as it tells the browser which methods are allowed generally
#     allow_origins = ["http://localhost:3000"]
#     allow_credentials = true
#     expose_headers    = []
#     max_age           = 300
#   }
# }

# # Lambda Permission to allow API Gateway to invoke
# resource "aws_lambda_permission" "api_gw_users" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.user-service.function_name
#   # Use the ARN of the Lambda function
#   principal  = "apigateway.amazonaws.com"
#   source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
# }

# resource "aws_lambda_permission" "api_gw_products" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.product-service.function_name
#   # Use the ARN of the Lambda function
#   principal  = "apigateway.amazonaws.com"
#   source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
# }

# # Integration
# resource "aws_apigatewayv2_integration" "lambda_integration_users" {
#   api_id                 = aws_apigatewayv2_api.api.id
#   integration_type       = "AWS_PROXY"
#   integration_uri        = aws_lambda_function.user-service.invoke_arn
#   integration_method     = "POST"
#   payload_format_version = "2.0"
# }

# # Route for POST /users
# resource "aws_apigatewayv2_route" "users_post" {
#   api_id    = aws_apigatewayv2_api.api.id
#   route_key = "ANY /users"
#   target    = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}"
# authorization_type = "JWT"
#   authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id
# }

# resource "aws_apigatewayv2_route" "users_with_id" {
#   api_id        = aws_apigatewayv2_api.api.id
#   route_key     = "ANY /users/{id}"
#   target        = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}"
#   authorization_type = "JWT"
#   authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id

# }


# #for produccts
# # Integration
# resource "aws_apigatewayv2_integration" "lambda_integration_products" {
#   api_id                 = aws_apigatewayv2_api.api.id
#   integration_type       = "AWS_PROXY"
#   integration_uri        = aws_lambda_function.product-service.invoke_arn
#   integration_method     = "POST"
#   payload_format_version = "2.0"
# }

# # Route for POST /products
# resource "aws_apigatewayv2_route" "products_post" {
#   api_id        = aws_apigatewayv2_api.api.id
#   route_key     = "ANY /products"
#   target        = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
#   authorization_type = "JWT"
#   authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id

# }

# resource "aws_apigatewayv2_route" "products_with_id" {
#   api_id        = aws_apigatewayv2_api.api.id
#   route_key     = "ANY /products/{id}"
#   target        = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
#   authorization_type = "JWT"
#   authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id

# }

# # Deploy stage
# resource "aws_apigatewayv2_stage" "default" {
#   api_id      = aws_apigatewayv2_api.api.id
#   name        = "$default"
#   auto_deploy = true
# }

# # resource "aws_apigatewayv2_authorizer" "cognito_auth" {
# #   api_id          = aws_apigatewayv2_api.api.id
# #   authorizer_type = "JWT"
# #   identity_sources = ["$request.header.Authorization"]
# #   name            = "cognito-authorizer"
# #   jwt_configuration {
# #     audience = [aws_cognito_user_pool_client.user_pool_client.id]
# #     issuer   = "https://${aws_cognito_user_pool.user_pool.endpoint}"
# #   }
# #   depends_on = [ aws_cognito_user_pool_client.user_pool_client, aws_cognito_user_pool.user_pool ]
# # }


# # Output the API URL
# output "api_endpoint" {
#   value = aws_apigatewayv2_api.api.api_endpoint
# }

# Assume these resources are defined elsewhere and are available:
# - aws_cognito_user_pool.user_pool
# - aws_cognito_user_pool_client.user_pool_client
# - aws_lambda_function.user-service
# - aws_lambda_function.product-service

# API Gateway (HTTP API v2)
resource "aws_apigatewayv2_api" "api" {
  name          = "api-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
    allow_methods     = ["*"] # Keep this as it tells the browser which methods are allowed generally
    allow_origins     = ["http://localhost:3000","https://${aws_lb.app_lb.dns_name}"]
    allow_credentials = true
    expose_headers    = []
    max_age           = 300
  }
}

# Lambda Permissions to allow API Gateway to invoke (keep as is, they are correct)
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

# JWT Authorizer Definition (keep as is, it's correct)
# resource "aws_apigatewayv2_authorizer" "jwt_auth" {
#   api_id          = aws_apigatewayv2_api.api.id
#   authorizer_type = "JWT"
#   identity_sources = ["$request.header.Authorization"]
#   name            = "CognitoJwtAuthorizer"
#   jwt_configuration {
#     issuer   = "https://cognito-idp.${aws_cognito_user_pool.user_pool.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
#     audience = [aws_cognito_user_pool_client.user_pool_client.id]
#   }
#   depends_on = [
#     aws_cognito_user_pool.user_pool,
#     aws_cognito_user_pool_client.user_pool_client
#   ]
# }

# Integration for Users Lambda (keep as is)
resource "aws_apigatewayv2_integration" "lambda_integration_users" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.user-service.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# --- NEW: Explicit OPTIONS routes for CORS Preflight ---

# OPTIONS /users route (no authorization needed for preflight)
resource "aws_apigatewayv2_route" "options_users" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "OPTIONS /users"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}" # Link to new OPTIONS integration
  authorization_type = "NONE"                                                                     # Crucial: No authorization for OPTIONS
}

# Dummy Integration for OPTIONS /users (HTTP API doesn't need a mock, just a direct response)
# But we need an integration target for the route. A MOCK integration is typical for REST APIs.
# For HTTP APIs, if `cors_configuration` is set on the API, it usually handles OPTIONS requests directly.
# However, if an explicit OPTIONS route is defined, it *will* route.
# A "NONE" integration or simply omitting `target` on HTTP API OPTIONS routes can work.
# Let's use a very basic mock integration for clarity if needed, or rely on CORS config.
# If CORS config doesn't fully handle it and a route is matched, a simple mock or default response is needed.
# For HTTP API, a common pattern for CORS OPTIONS when routes are defined is *not* to use a target.
# Let's try without a target first, as per some examples, or with a minimal "passthrough" integration type if necessary.

# Let's try to remove authorization from the OPTIONS preflight via a dedicated route.
# If CORS is configured on the API, it handles OPTIONS. But if there's an ANY route with auth, it conflicts.
# The best practice for HTTP API when authorizers are on ANY routes is indeed to create explicit OPTIONS routes.
# The target for OPTIONS can be a dummy (like a mock in REST API) or a very minimal Lambda that just returns 200 with headers.
# For HTTP API v2, `integration_type = "MOCK"` is not available directly for `aws_apigatewayv2_integration`.
# A common workaround for OPTIONS routes without a real backend is a "passthrough" or a tiny Lambda.
# For simplicity, let's create a dummy Lambda for OPTIONS if a route needs a target.
# However, the primary goal is to make the OPTIONS route `authorization_type = "NONE"`.

# --- Corrected Approach for OPTIONS routes in HTTP API v2 with Authorizers ---
# When you have an ANY method with JWT authorizer, the OPTIONS preflight itself will be authorized.
# To fix this, you must create a *separate* OPTIONS route and set its authorization to NONE.
# API Gateway HTTP API will then process this OPTIONS route before the ANY route.

# Dummy Integration for OPTIONS if a target is required (simplest is a passthrough Lambda)
# If your Lambda is universal and handles all methods, it might just return 200 for OPTIONS based on its code.
# Assuming you have a user-service Lambda that handles /users for all methods.

# If the `ANY` route authorization is JWT, the OPTIONS also gets JWT.
# The best way to make the OPTIONS pass is to define it specifically with NONE authorization.
# The `cors_configuration` on the API should take care of the response headers if the route has `NONE` auth.

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
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}" # Can point to your users Lambda, but Lambda should return 200 for OPTIONS
  authorization_type = "NONE"                                                                     # Crucial: No authorization for OPTIONS
}

# Route for ANY /users/{id}
resource "aws_apigatewayv2_route" "users_with_id_any" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /users/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}


# Integration for Products Lambda (keep as is)
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
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}" # Can point to your products Lambda
  authorization_type = "NONE"                                                                        # Crucial: No authorization for OPTIONS
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
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}" # Can point to your products Lambda
  authorization_type = "NONE"                                                                        # Crucial: No authorization for OPTIONS
}

# Route for ANY /products/{id}
resource "aws_apigatewayv2_route" "products_with_id_any" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /products/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}

# Deploy stage (keep as is)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Output the API URL (keep as is)
output "api_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}