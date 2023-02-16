terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1"

}

variable "lambda-function-name" {
  type = string
  description = "Name of AWS Lambda Function"
}

resource "aws_cloudwatch_log_group" "cloudwatch-lambda-logroup" {
  name = "/aws/lambda/${var.lambda-function-name}"
  retention_in_days = 14
}


data "aws_iam_policy_document" "lambda-role-trust-policy-doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "lambda.amazonaws.com" ]
    }
  }
}

data "aws_iam_policy_document" "lambda-role-policy-doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [ "logs:CreateLogStream", "logs:PutLogEvents" ]
    resources = [ "${aws_cloudwatch_log_group.cloudwatch-lambda-logroup.arn}:*" ]
  }
  depends_on = [
    aws_cloudwatch_log_group.cloudwatch-lambda-logroup
  ]
}

resource "aws_iam_role" "lambda-execution-role" {
  name               = "lambda-${var.lambda-function-name}"
  assume_role_policy = data.aws_iam_policy_document.lambda-role-trust-policy-doc.json 
}

resource "aws_iam_policy" "lambda-execution-role-policy" {
  name        = "lambda-${var.lambda-function-name}"
  path        = "/"
  description = "AWS IAM Policy granting permission to Lambda Function Role"
  policy      = data.aws_iam_policy_document.lambda-role-policy-doc.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_to_iam_lambda_role" {
  role       = aws_iam_role.lambda-execution-role.name
  policy_arn = aws_iam_policy.lambda-execution-role-policy.arn
  depends_on = [
    aws_iam_policy.lambda-execution-role-policy,
    aws_iam_role.lambda-execution-role
  ]
}


data "archive_file" "lambda_function_zip" {
  type = "zip"
  source_dir = "${path.module}/build"
  output_file_mode = "0666"
  output_path = "${path.module}/dist/lambda.function.js.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.lambda-function-name
  role = aws_iam_role.lambda-execution-role.arn
  handler = "app.lambdaHandler"
  filename = data.archive_file.lambda_function_zip.output_path
  source_code_hash = data.archive_file.lambda_function_zip.output_base64sha256
  runtime = "nodejs18.x" # Valid runtime values: https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html
  depends_on = [
    aws_iam_role_policy_attachment.attach_lambda_policy_to_iam_lambda_role
  ]
}