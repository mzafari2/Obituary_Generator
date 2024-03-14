terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

# two lambda functions w/ function url
# one dynamodb table
# roles and policies as needed
# step functions (if you're going for the bonus marks)

locals {
  function_name_get    = "get-obituary"
  function_name_create = "create-obituary"
  function_name        = "last-show"
  handler_name         = "main.lambda_handler"
  artifact_name        = "artifact.zip"
}

# create a role for the Lambda function to assume
# every service on AWS that wants to call other AWS services should first assume a role and
# then any policy attached to the role will give permissions
# to the service so it can interact with other AWS services
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "lambda" {
  name               = "iam-for-lambda-${local.function_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# create a Lambda function
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "lambda_create" {
  #s3_bucket = aws_s3_bucket.lambda.bucket
  # the artifact needs to be in the bucket first. Otherwise, this will fail.
  #s3_key        = local.artifact_name
  role             = aws_iam_role.lambda.arn
  function_name    = local.function_name_create
  handler          = local.handler_name
  filename         = data.archive_file.data_lambda_create.output_path
  source_code_hash = data.archive_file.data_lambda_create.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
  timeout = 20
}

data "archive_file" "data_lambda_create" {
  type = "zip"
  # this file (main.py) needs to exist in the same folder as this 
  # Terraform configuration file
  source_dir  = "../functions/create-obituary"
  output_path = "create_artifact.zip"
}

# create a Lambda function
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "lambda_get" {
  #s3_bucket = aws_s3_bucket.lambda.bucket
  # the artifact needs to be in the bucket first. Otherwise, this will fail.
  #s3_key        = local.artifact_name
  role             = aws_iam_role.lambda.arn
  function_name    = local.function_name_get
  handler          = local.handler_name
  filename         = data.archive_file.data_lambda_get.output_path
  source_code_hash = data.archive_file.data_lambda_get.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

data "archive_file" "data_lambda_get" {
  type = "zip"
  # this file (main.py) needs to exist in the same folder as this 
  # Terraform configuration file
  source_file = "../functions/get-obituaries/main.py"
  output_path = "get_artifact.zip"
}

# create a policy for publishing logs to CloudWatch
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "logs" {
  name        = "lambda-logging-${local.function_name}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ssm:GetParametersByPath",
        "polly:SynthesizeSpeech",
        "dynamodb:PutItem",
        "dynamodb:Scan"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "*"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

# attach the above policy to the function role
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.logs.arn
}

# read the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "obituary" {
  name           = "obituary-30118953"
  billing_mode   = "PROVISIONED"
  write_capacity = 1
  read_capacity  = 1
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}

resource "aws_lambda_function_url" "url_get" {
  function_name      = aws_lambda_function.lambda_get.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_lambda_function_url" "url_create" {
  function_name      = aws_lambda_function.lambda_create.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

# show the Function URL after creation
output "lambda_url_create" {
  value = aws_lambda_function_url.url_create.function_url
}

# show the Function URL after creation
output "lambda_url-get" {
  value = aws_lambda_function_url.url_get.function_url
}


