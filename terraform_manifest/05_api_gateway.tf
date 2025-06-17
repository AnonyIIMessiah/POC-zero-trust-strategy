# data "aws_iam_policy_document" "assume_role_api_gateway" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["apigateway.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }
# resource "aws_iam_role" "iam_for_api_gateway" {
#   name = "iam_for_api_gateway"

#   assume_role_policy = data.aws_iam_policy_document.assume_role_api_gateway.json
# }

# # resource "aws_iam_role_policy_attachment" "sqs_access_api_gateway" {
# #   role       = aws_iam_role.iam_for_api_gateway.name
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
# # }



# resource "aws_apigatewayv2_api" "api_gateway" {
#   name          = "publish_to_lambda"
#   protocol_type = "HTTP"
# }

# resource "aws_apigatewayv2_route" "route_products" {
#   api_id    = aws_apigatewayv2_api.api_gateway.id
#   route_key = "ANY /products"

#   target = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
# }

# resource "aws_apigatewayv2_integration" "lambda_integration_products" {
#   api_id              = aws_apigatewayv2_api.api_gateway.id
#   integration_type    = "AWS_PROXY"
#   integration_subtype = "SQS-SendMessage"
#   # integration_uri    = aws_sqs_queue.terraform_queue.arn
#   request_parameters = {
#     "QueueUrl"    = aws_sqs_queue.terraform_queue.id
#     "MessageBody" = "$request.body.MessageBody"
#   }
#   credentials_arn        = aws_iam_role.iam_for_api_gateway.arn
#   payload_format_version = "1.0"
#   timeout_milliseconds   = 10000

# }

# # resource "aws_apigatewayv2_integration" "example" {
# #   api_id              = aws_apigatewayv2_api.example.id
# #   credentials_arn     = aws_iam_role.example.arn
# #   description         = "SQS example"
# #   integration_type    = "AWS_PROXY"
# #   integration_subtype = "SQS-SendMessage"

# #   request_parameters = {
# #     "QueueUrl"    = "$request.header.queueUrl"
# #     "MessageBody" = "$request.body.message"
# #   }
# # }

# resource "aws_apigatewayv2_stage" "default" {
#   api_id      = aws_apigatewayv2_api.api_gateway.id
#   name        = "$default"
#   auto_deploy = true
# }


# output "api_gateway_endpoint" {
#   value = aws_apigatewayv2_api.api_gateway.api_endpoint
# }



# API Gateway (HTTP API v2)
resource "aws_apigatewayv2_api" "api" {
  name          = "api-gateway"
  protocol_type = "HTTP"
}

# Lambda Permission to allow API Gateway to invoke
resource "aws_lambda_permission" "api_gw_users" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user-service.function_name
  # Use the ARN of the Lambda function
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_products" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product-service.function_name
  # Use the ARN of the Lambda function
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Integration
resource "aws_apigatewayv2_integration" "lambda_integration_users" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.user-service.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route for POST /users
resource "aws_apigatewayv2_route" "users_post" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /users"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}"
authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id
}

resource "aws_apigatewayv2_route" "users_with_id" {
  api_id        = aws_apigatewayv2_api.api.id
  route_key     = "ANY /users/{id}"
  target        = "integrations/${aws_apigatewayv2_integration.lambda_integration_users.id}"
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id

}


#for produccts
# Integration
resource "aws_apigatewayv2_integration" "lambda_integration_products" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.product-service.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route for POST /products
resource "aws_apigatewayv2_route" "products_post" {
  api_id        = aws_apigatewayv2_api.api.id
  route_key     = "ANY /products"
  target        = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id

}

resource "aws_apigatewayv2_route" "products_with_id" {
  api_id        = aws_apigatewayv2_api.api.id
  route_key     = "ANY /products/{id}"
  target        = "integrations/${aws_apigatewayv2_integration.lambda_integration_products.id}"
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.jwt_auth.id

}

# Deploy stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# resource "aws_apigatewayv2_authorizer" "cognito_auth" {
#   api_id          = aws_apigatewayv2_api.api.id
#   authorizer_type = "JWT"
#   identity_sources = ["$request.header.Authorization"]
#   name            = "cognito-authorizer"
#   jwt_configuration {
#     audience = [aws_cognito_user_pool_client.user_pool_client.id]
#     issuer   = "https://${aws_cognito_user_pool.user_pool.endpoint}"
#   }
#   depends_on = [ aws_cognito_user_pool_client.user_pool_client, aws_cognito_user_pool.user_pool ]
# }


# Output the API URL
output "api_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

