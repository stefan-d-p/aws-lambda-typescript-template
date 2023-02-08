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

resource "aws_iam_role" "lambda-template-role" {
  name               = "aws_lambda_template_role"
  assume_role_policy = file("${path.module}/aws/lambda_role_iam_trustpolicy.json")
}

resource "aws_iam_policy" "lambda-template-policy" {
  name        = "aws_lambda_template_policy"
  path        = "/"
  description = "AWS IAM Policy granting permission to Lambda Function Role"
  policy      = file("${path.module}/aws/lambda_role_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_to_iam_lambda_role" {
  role       = aws_iam_role.lambda-template-role.name
  policy_arn = aws_iam_policy.lambda-template-policy.arn
}

data "archive_file" "lambda_function_zip" {
  type = "zip"
  source_dir = "${path.module}/build"
  output_file_mode = "0666"
  output_path = "${path.module}/dist/lambda.function.js.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "tf_lambda"
  role = aws_iam_role.lambda-template-role.arn
  handler = "app.lambdaHandler"
  filename = data.archive_file.lambda_function_zip.output_path
  source_code_hash = data.archive_file.lambda_function_zip.output_base64sha256
  runtime = "nodejs16.x" 
}