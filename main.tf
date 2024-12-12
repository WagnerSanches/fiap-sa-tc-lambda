provider "aws" {
  region = "us-east-1"
}

data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "stuff-authorizer"
  output_path = "stuff-authorizer.zip"

}

data "aws_api_gateway_rest_api" "existing_api" {
  name = "${var.name_app}-pvt-endpoint"
}

resource "aws_api_gateway_resource" "stuff_resource" {
  rest_api_id = data.aws_api_gateway_rest_api.existing_api.id
  parent_id   = data.aws_api_gateway_rest_api.existing_api.root_resource_id
  path_part   = "stuff"
}

resource "aws_lambda_function" "authorizer" {
  filename         = "stuff-authorizer.zip"
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  function_name    = "stuff-authorizer"
  role             = aws_iam_role.authorizer_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  publish          = true
}

resource "aws_iam_role" "authorizer_role" {
  name = "your-lambda-authorizer-role"

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

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "your-authorizer-name"
  rest_api_id            = data.aws_api_gateway_rest_api.existing_api.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.authorizer_role.arn
}

resource "aws_api_gateway_method" "stuff_method" {
  rest_api_id   = data.aws_api_gateway_rest_api.existing_api.id
  resource_id   = aws_api_gateway_resource.stuff_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
}

resource "aws_api_gateway_integration" "stuff_integration" {
  rest_api_id             = data.aws_api_gateway_rest_api.existing_api.id
  resource_id             = aws_api_gateway_resource.stuff_resource.id
  http_method             = aws_api_gateway_method.stuff_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.authorizer.invoke_arn
}