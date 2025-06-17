
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "dynamodb_access_users" {
  name        = "LambdaDynamoDBAccessUsers"
  description = "Allow Lambda to access DynamoDB Products table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ],
        Resource = "arn:aws:dynamodb:ap-south-1:615015051504:table/Users"
      }
    ]
  })
}





resource "aws_iam_role_policy_attachment" "dynamodb_access_users_attachment" {
  policy_arn = aws_iam_policy.dynamodb_access_users.arn
  role       = aws_iam_role.iam_for_lambda.name
}

# resource "aws_iam_role_policy_attachment" "db_access" {
#   role       = aws_iam_role.iam_for_lambda.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
# }

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda.name
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../02_user_Service"     # Directory to archive
  output_path = "../02_user_Service.zip" # Output zip file
}

resource "aws_lambda_function" "user-service" {
  filename         = "../02_user_Service.zip"
  function_name    = "user-service"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda.output_base64sha256


  vpc_config {
    subnet_ids         = [aws_subnet.Private-subnet-1.id, aws_subnet.Private-subnet-2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}


resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Security group for private Lambda"
  vpc_id      = aws_vpc.POC-01.id # Replace with your actual VPC

  # Egress rule to allow outbound traffic (e.g., to DynamoDB endpoint)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Or more specific range (like only DynamoDB VPC endpoint range)
  }


}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_permission" "allow_apigateway_user_service" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user-service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_apigatewayv2_api.api.execution_arn # for HTTP API or REST API
}
