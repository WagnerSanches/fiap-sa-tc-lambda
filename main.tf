provider "aws" {
  region = "us-east-1"
}

data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "product-authorizer"
  output_path = "product-authorizer.zip"
}

resource "aws_lambda_function" "authorizer" {
  filename         = "product-authorizer.zip"
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  function_name    = "product-authorizer"
  role             = aws_iam_role.authorizer_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  publish          = true
}

resource "aws_iam_role" "authorizer_role" {
  name = "lambda-authorizer"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = var.api_id  
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.authorizer.arn
  payload_format_version = "2.0"  

}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = var.api_id  
  route_key = "POST /login"         

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
